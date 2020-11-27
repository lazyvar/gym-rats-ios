//
//  CreateWorkoutViewController.swift
//  GymRats
//
//  Created by Mack Hasz on 2/6/19.
//  Copyright © 2019 Mack Hasz. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import GooglePlaces
import Eureka
import HealthKit

protocol CreatedWorkoutDelegate: class {
  func createWorkoutController(_ createWorkoutController: CreateWorkoutViewController, created workout: Workout)
}

class CreateWorkoutViewController: GRFormViewController {
    enum ChangeType {
      case create
      case update
    }
  
    weak var delegate: CreatedWorkoutDelegate?

    var changeType: ChangeType = .update
  
    let disposeBag = DisposeBag()
    let placeLikelihoods = BehaviorRelay<[Place]>(value: [])
    let place = BehaviorRelay<Place?>(value: nil)
    
    let workoutDescription = BehaviorRelay<String?>(value: nil)
    let workoutTitle = BehaviorRelay<String?>(value: nil)
    let photo = BehaviorRelay<Either<UIImage, Workout>?>(value: nil)
    
    let duration = BehaviorRelay<String?>(value: nil)
    let distance = BehaviorRelay<String?>(value: nil)
    let steps = BehaviorRelay<String?>(value: nil)
    let calories = BehaviorRelay<String?>(value: nil)
    let points = BehaviorRelay<String?>(value: nil)

    lazy var workoutDescriptionThing = self.workoutHeader.map { $0?.description }
    lazy var workoutTitleThing = self.workoutHeader.map { $0?.title }
    lazy var photoThing = self.workoutHeader.map { $0?.imageOrWorkout }

    let workoutHeader = BehaviorRelay<WorkoutHeaderInfo?>(value: nil)
    
    var challenges: [Int: BehaviorRelay<Bool>] = [:]
    var workoutOrImage: Either<UIImage, Workout>
    var workout: Workout?
    var healthKitWorkout: HKWorkout?

    lazy var submitButton = UIBarButtonItem(title: "Post", style: .done, target: self, action: #selector(postWorkout))
    lazy var cancelButton = UIBarButtonItem.close(target: self).apply {
      $0.setTitleTextAttributes([
        NSAttributedString.Key.font: UIFont.body
      ], for: .normal)
    }

    let placeRow = PushRow<Place>() {
        $0.title = "Current location"
    }
    .cellSetup { cell, _ in
        cell.tintColor = .primaryText
        cell.height = { return 48 }
        cell.textLabel?.font = .body
        cell.detailTextLabel?.font = .body
    }
    .onPresent { _, selector in
        selector.enableDeselection = false
    }
    
    lazy var placeButtonRow = ButtonRow("place") {
        $0.title = "Check in location"
    }.cellSetup { cell, _ in
        cell.textLabel?.font = .body
        cell.tintColor = .primaryText
        cell.height = { return 48 }
        cell.imageView?.image = .map
    }.onCellSelection { [weak self] _, _ in
        self?.pickPlace()
        self?.showLoadingBar()
    }.cellUpdate { cell, row in
      cell.textLabel?.textAlignment = .left
      cell.accessoryType = .disclosureIndicator
    }
    
    init(workout: Either<UIImage, Workout>) {
      self.workoutOrImage = workout
      self.workout = workout.right
      
      switch workout {
      case .left:
        changeType = .create
      case .right:
        changeType = .update
      }
      
      super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
      super.viewDidLoad()
      
      submitButton.tintColor = .brand
      navigationItem.rightBarButtonItem = submitButton
      navigationItem.leftBarButtonItem = cancelButton
      
      tableView.backgroundColor = .background
      navigationItem.largeTitleDisplayMode = .never
      
      switch changeType {
      case .create:
        navigationItem.title = "New workout"
      case .update:
        navigationItem.title = "Update workout"
        submitButton.title = "Save"
      }
      
      LabelRow.defaultCellUpdate = nil

      let activeChallenges = (Challenge.State.all.state?.object ?? []).getActiveChallenges()
      
        let headerRow = CreateWorkoutHeaderRow("workout_header") {
          $0.tag = "header_row"
          $0.value = WorkoutHeaderInfo(imageOrWorkout: workoutOrImage, title: workoutOrImage.right?.title ?? "", description: workoutOrImage.right?.description ?? "")
        }

        let durationRow = TextRow("duration") {
          $0.title = "Duration (mins)"
          $0.placeholder = "-"
          $0.value = workoutOrImage.right?.duration?.stringify
        }.cellSetup { cell, _ in
            cell.textLabel?.font = .body
            cell.titleLabel?.font = .body
            cell.height = { return 48 }
            cell.tintColor = .brand
            cell.textField.keyboardType = .numberPad
        }

        let distanceRow = TextRow("distance") {
            $0.title = "Distance (miles)"
            $0.placeholder = "-"
            $0.value = workoutOrImage.right?.distance
        }.cellSetup { cell, _ in
            cell.textLabel?.font = .body
            cell.titleLabel?.font = .body
            cell.height = { return 48 }
            cell.tintColor = .brand
            cell.textField.keyboardType = .decimalPad
        }

        let stepsRow = TextRow("steps") {
            $0.title = "Steps"
            $0.placeholder = "-"
            $0.value = workoutOrImage.right?.steps?.stringify
        }.cellSetup { cell, _ in
            cell.textLabel?.font = .body
            cell.titleLabel?.font = .body
            cell.height = { return 48 }
            cell.tintColor = .brand
            cell.textField.keyboardType = .numberPad
        }

        let caloriesRow = TextRow("cals") {
            $0.title = "Calories"
            $0.placeholder = "-"
            $0.value = workoutOrImage.right?.calories?.stringify
        }.cellSetup { cell, _ in
            cell.textLabel?.font = .body
            cell.titleLabel?.font = .body
            cell.height = { return 48 }
            cell.tintColor = .brand
            cell.textField.keyboardType = .numberPad
        }

        let pointsRow = TextRow("points") {
            $0.title = "Points"
            $0.placeholder = "-"
            $0.value = workoutOrImage.right?.points?.stringify
        }.cellSetup { cell, _ in
            cell.textLabel?.font = .body
            cell.titleLabel?.font = .body
            cell.height = { return 48 }
            cell.tintColor = .brand
            cell.textField.keyboardType = .numberPad
        }

        let challengeSection = Section("Challenges")
      
        let headerSection = Section() {
          $0.tag = "the-form"
        }
        <<< headerRow
          
      let dataSection = Section() { $0.tag = "data" }
          <<< durationRow
          <<< distanceRow
          <<< caloriesRow
          <<< stepsRow
          <<< pointsRow
      
      let extra = Section() { $0.tag = "extra" }
      
      let importDataRow = ButtonRow("import-data") {
        $0.title = "Import workout from the Health App"
        $0.tag = "import-data-row"
      }.cellSetup { cell, _ in
          cell.textLabel?.font = .body
          cell.tintColor = .primaryText
          cell.height = { return 48 }
          cell.imageView?.image = .smallAppleHealth
          cell.imageView?.layer.borderWidth = 1
          cell.imageView?.clipsToBounds = true
          cell.imageView?.layer.cornerRadius = 4
          cell.imageView?.layer.borderColor = UIColor.background.cgColor
      }.onCellSelection { [weak self] _, _ in
        self?.importWorkout()
      }.cellUpdate { cell, row in
        cell.textLabel?.textAlignment = .left
        cell.accessoryType = .disclosureIndicator
      }
      
        extra <<< importDataRow
        extra <<< placeButtonRow
      
      form +++ headerSection

      if changeType == .create {
        form +++ extra
      }
        form +++ dataSection

        activeChallenges.forEach { challenge in
            let row = SwitchRow("challenge_\(challenge.id)") {
                $0.title = "\(challenge.name)"
                $0.value = true
            }.cellSetup { cell, _ in
                cell.height = { return 48 }
            }
            
            let relay = BehaviorRelay(value: true)
            row.rx.value.map { $0 ?? true }.bind(to: relay).disposed(by: disposeBag)
            self.challenges[challenge.id] = relay
            
            challengeSection <<< row
        }
        
      if activeChallenges.count > 1 && changeType == .create {
            form +++ challengeSection
        }
        
        placeLikelihoods.asObservable()
            .subscribe { [weak self] event in
                switch event {
                case .next(let val):
                    self?.placeRow.options = val
                    self?.placeRow.value = val.first
                    self?.placeRow.reload()
                case .error:
                    // TODO
                    break
                default:
                    break
                }
            }.disposed(by: disposeBag)
        
        headerRow.rx.value.bind(to: self.workoutHeader).disposed(by: disposeBag)
        
        durationRow.rx.value.bind(to: self.duration).disposed(by: disposeBag)
        distanceRow.rx.value.bind(to: self.distance).disposed(by: disposeBag)
        stepsRow.rx.value.bind(to: self.steps).disposed(by: disposeBag)
        caloriesRow.rx.value.bind(to: self.calories).disposed(by: disposeBag)
        pointsRow.rx.value.bind(to: self.points).disposed(by: disposeBag)

        workoutDescriptionThing.bind(to: workoutDescription).disposed(by: disposeBag)
        workoutTitleThing.bind(to: workoutTitle).disposed(by: disposeBag)
        photoThing.bind(to: photo).disposed(by: disposeBag)
        placeRow.rx.value.bind(to: self.place).disposed(by: disposeBag)
        
        let titlePresent = self.workoutTitle.asObservable().isPresent
        let photoPresent = self.photo.asObservable().isPresent

      let atLeastOneChallenge = Observable<Bool>.combineLatest(self.challenges.values) { vals in
            return vals.reduce(false) { $0 || $1 }
        }
        
        Observable<Bool>.combineLatest(titlePresent, photoPresent, atLeastOneChallenge) { titlePresent, photoPresent, atLeastOneChallenge in
            return titlePresent && photoPresent && atLeastOneChallenge
        }
        .bind(to: self.submitButton.rx.isEnabled).disposed(by: disposeBag)
    }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
  
    switch changeType {
    case .create:
      Track.screen(.createWorkout)
    case .update:
      Track.screen(.editWorkout)
    }
  }
  
    var locationManager: CLLocationManager?
    
    func pickPlace() {
      locationManager = CLLocationManager()
      locationManager?.delegate = self
      locationManager?.requestWhenInUseAuthorization()
    }
    
    func getPlacesForCurrentLocation() {
        let fields: GMSPlaceField = GMSPlaceField(rawValue:
          UInt(GMSPlaceField.name.rawValue)
          | UInt(GMSPlaceField.placeID.rawValue)
        )!
        
        GMSPlacesClient.shared().findPlaceLikelihoodsFromCurrentLocation(withPlaceFields: fields, callback: { [weak self] placeLikelihoods, error in
            self?.hideLoadingBar()
            if let error = error {
                print("An error occurred: \(error.localizedDescription)")
                return
            }
            
            guard
              let self = self,
              let places = placeLikelihoods?.sorted(by: { $0.likelihood > $1.likelihood }).map({ Place(from: $0.place) })
            else { return }

            self.form.sectionBy(tag: "extra")?.remove(at: 1) // yikes
            var section = self.form.sectionBy(tag: "extra")
            section?.insert(self.placeRow, at: 1)
  
            var seen: [String: Bool] = [:]
          
          self.placeLikelihoods.accept(places.compactMap { p in p }.filter { seen.updateValue(true, forKey: $0.name) == nil })
        })
    }
  
  func importWorkout() {
    HealthService.requestAuthorization(toShare: nil, read: Set([.workoutType()]))
      .subscribe(onSuccess: { _ in
        DispatchQueue.main.async {
          let importWorkoutViewController = ImportWorkoutViewController()
          importWorkoutViewController.delegate = self
          
          self.presentInNav(importWorkoutViewController)
        }
      }, onError: { error in
        DispatchQueue.main.async {
          let importWorkoutViewController = ImportWorkoutViewController()
          importWorkoutViewController.delegate = self
          
          self.presentInNav(importWorkoutViewController)
        }
      })
      .disposed(by: disposeBag)
  }
  
    @objc func postWorkout() {
      guard (workoutTitle.value ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isNotEmpty else { presentAlert(title: "Uh-oh", message: "A title is required."); return }

      showLoadingBar(disallowUserInteraction: true)
        
      switch changeType {
      case .create:
        createWorkout()
      case .update:
        updateWorkout()
      }
    }
  
  func createWorkout() {
    guard let image = photo.value?.left else { return }
    
    let challenges = self.challenges
        .filter { $0.value.value }
        .map { $0.key }
    
    let newWorkout = NewWorkout(
      title: workoutTitle.value!,
      description: workoutDescription.value,
      photo: image,
      googlePlaceId: place.value?.id,
      duration: duration.value.map { Int($0) } ?? nil,
      distance: distance.value,
      steps: steps.value.map { Int($0) } ?? nil,
      calories: calories.value.map { Int($0) } ?? nil,
      points: points.value.map { Int($0) } ?? nil,
      appleDeviceName: healthKitWorkout?.device?.name,
      appleSourceName: healthKitWorkout?.sourceRevision.source.name,
      appleWorkoutUuid: healthKitWorkout?.uuid.uuidString,
      activityType: healthKitWorkout?.workoutActivityType.activityify
    )
    
    gymRatsAPI.postWorkout(newWorkout, challenges: challenges)
      .subscribe(onNext: { [weak self] result in
        guard let self = self else { return }
        
        self.hideLoadingBar()
        
        switch result {
        case .success(let workout):
          Track.event(.workoutLogged)
          StoreService.requestReview()
          self.delegate?.createWorkoutController(self, created: workout)
        case .failure(let error):
          self.presentAlert(with: error)
        }
      })
      .disposed(by: disposeBag)
  }
  
  func updateWorkout() {
    guard let workout = workout else { return }
    guard let photo = photo.value else { return }
    
    let newWorkout = UpdateWorkout(
      id: workout.id,
      title: workoutTitle.value!,
      description: workoutDescription.value,
      photo: photo,
      duration: duration.value.map { Int($0) } ?? nil,
      distance: distance.value,
      steps: steps.value.map { Int($0) } ?? nil,
      calories: calories.value.map { Int($0) } ?? nil,
      points: points.value.map { Int($0) } ?? nil
    )
    
    gymRatsAPI.update(newWorkout)
      .subscribe(onNext: { [weak self] result in
        guard let self = self else { return }
        
        self.hideLoadingBar()
        
        switch result {
        case .success(let workout):
          self.delegate?.createWorkoutController(self, created: workout)
        case .failure(let error):
          self.presentAlert(with: error)
        }
      })
      .disposed(by: disposeBag)
  }
}

extension CreateWorkoutViewController: ImportWorkoutViewControllerDelegate {
  func importWorkoutViewController(_ importWorkoutViewController: ImportWorkoutViewController, imported workout: HKWorkout) {
    importWorkoutViewController.dismissSelf()
    healthKitWorkout = workout
    
    if let calories = workout.totalEnergyBurned {
      form.rowBy(tag: "cals")?.value = String(Int(calories.doubleValue(for: .kilocalorie()).rounded()))
      form.rowBy(tag: "cals")?.baseCell.isUserInteractionEnabled = false
      (form.rowBy(tag: "cals")?.baseCell as? TextCell)?.textField.delegate = self
    }
    
    if let distance = workout.totalDistance {
      form.rowBy(tag: "distance")?.value = String(distance.doubleValue(for: .mile()).rounded(places: 1))
      form.rowBy(tag: "distance")?.baseCell.isUserInteractionEnabled = false
      (form.rowBy(tag: "distance")?.baseCell as? TextCell)?.textField.delegate = self
    }
    
    form.rowBy(tag: "duration")?.value = Int(workout.duration / 60).stringify
    form.rowBy(tag: "duration")?.baseCell.isUserInteractionEnabled = false
    (form.rowBy(tag: "duration")?.baseCell as? TextCell)?.textField.delegate = self
    
    if let row = form.rowBy(tag: "import-data-row") {
      row.title = "\(workout.workoutActivityType.name) | \(workout.device?.name ?? workout.sourceRevision.source.name)"
      row.baseCell.textLabel?.numberOfLines = 0
    }
    
    if let header = workoutHeader.value, header.title == "" {
      let new = WorkoutHeaderInfo(imageOrWorkout: header.imageOrWorkout, title: workout.workoutActivityType.name, description: header.description)
      workoutHeader.accept(new)
      
      (form.rowBy(tag: "header_row") as? CreateWorkoutHeaderRow)?.value = new
    }
  }
}

extension CreateWorkoutViewController: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
    switch status {
    case .authorizedWhenInUse, .authorizedAlways:
      getPlacesForCurrentLocation()
    case .denied, .restricted:
      hideLoadingBar()
      presentAlert(title: "Location Permission Required", message: "To check in a location, please enable the permission in settings.")
    case .notDetermined:
      break
    @unknown default:
      break
    }
  }
  
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    // mt
  }
  
  func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    presentAlert(title: "Error Getting Location", message: "Please try again.")
  }
}

extension CreateWorkoutViewController: UITextFieldDelegate {
  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
    return false
  }
}

extension Double {
  /// Rounds the double to decimal places value
  func rounded(places: Int) -> Double {
    let divisor = pow(10.0, Double(places))
  
    return (self * divisor).rounded() / divisor
  }
}
