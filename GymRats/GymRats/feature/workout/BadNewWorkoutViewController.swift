//
//  NewWorkoutViewController.swift
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

protocol NewWorkoutDelegate: class {
    func newWorkoutController(_ newWorkoutController: BadNewWorkoutViewController, created workouts: [Workout])
}

class BadNewWorkoutViewController: GRFormViewController, Special {
    
    weak var delegate: NewWorkoutDelegate?

    let disposeBag = DisposeBag()
    let placeLikelihoods = BehaviorRelay<[Place]>(value: [])
    let place = BehaviorRelay<Place?>(value: nil)
    
    let workoutDescription = BehaviorRelay<String?>(value: nil)
    let workoutTitle = BehaviorRelay<String?>(value: nil)
    let photo = BehaviorRelay<UIImage?>(value: nil)
    
    lazy var workoutDescriptionThing = self.workoutHeader.map { $0?.description }
    lazy var workoutTitleThing = self.workoutHeader.map { $0?.title }
    lazy var photoThing = self.workoutHeader.map { $0?.image }

    let workoutHeader = BehaviorRelay<WorkoutHeaderInfo?>(value: nil)
    
    var challenges: [Int: BehaviorRelay<Bool>] = [:]
    var workoutImage: UIImage
    
    lazy var submitButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(postWorkout))
    lazy var cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(dismissSelf))

    let placeRow = PushRow<Place>() {
        $0.title = "Current Location"
        $0.selectorTitle = "Where are you?"
    }
    .cellSetup { cell, _ in
        cell.tintColor = .primaryText
        cell.height = { return 48 }
    }
    .onPresent { _, selector in
        selector.enableDeselection = false
    }
    
    lazy var placeButtonRow = ButtonRow("place") {
        $0.title = "Check In Location"
    }.cellSetup { cell, _ in
        cell.textLabel?.font = .body
        cell.tintColor = .primaryText
        cell.height = { return 48 }
    }.onCellSelection { [weak self] _, _ in
        self?.pickPlace()
        self?.showLoadingBar()
    }
    
    init(workoutImage: UIImage) {
        self.workoutImage = workoutImage
        
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

        title = "Log Workout"
        
        LabelRow.defaultCellUpdate = nil

        let headerRow = CreateWorkoutHeaderRow("workout_header") {
            $0.value = WorkoutHeaderInfo(image: workoutImage, title: "", description: "")
        }

        let activeChallenges = GymRatsApp.coordinator.menu.activeChallenges
        let challengeSection = Section("Challenges")
        
        form +++ Section() {
            $0.tag = "the-form"
        }
            <<< headerRow
            <<< placeButtonRow
        
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
        
        if activeChallenges.count > 1 {
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
    
    var locationManager: CLLocationManager?
    
    func pickPlace() {
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        
        locationManager?.requestWhenInUseAuthorization()
    }
    
    func getPlacesForCurrentLocation() {
        let fields: GMSPlaceField = GMSPlaceField(rawValue: UInt(GMSPlaceField.name.rawValue) |
            UInt(GMSPlaceField.placeID.rawValue))!
        
        GMSPlacesClient.shared().findPlaceLikelihoodsFromCurrentLocation(withPlaceFields: fields, callback: { [weak self] placeLikelihoods, error in
            self?.hideLoadingBar()
            if let error = error {
                print("An error occurred: \(error.localizedDescription)")
                return
            }
            
            guard
                let self = self,
                let places = placeLikelihoods?.sorted(by: { $0.likelihood > $1.likelihood }).map({ Place(from: $0.place) }).compacted()
            else { return }

            self.form.sectionBy(tag: "the-form")?.remove(at: 3) // yikes
            var section = self.form.sectionBy(tag: "the-form")
            section?.insert(self.placeRow, at: 3)
  
            self.placeLikelihoods.accept(places.unique())
        })
    }
    
    @objc func postWorkout() {
        showLoadingBar(disallowUserInteraction: true)
        
        let challenges = self.challenges
            .filter { $0.value.value }
            .map { $0.key }
        
        gymRatsAPI.postWorkout (
            title: workoutTitle.value!,
            description: workoutDescription.value,
            photo: photo.value,
            googlePlaceId: place.value?.id,
            challenges: challenges
        ).subscribe(onNext: { [weak self] workouts in
            guard let self = self else { return }
            
            Track.event(.workoutLogged)
            self.hideLoadingBar()
            self.navigationController?.popViewController(animated: true)
            StoreService.requestReview()
            self.delegate?.newWorkoutController(self, created: workouts)
        }, onError: { [weak self] error in
            self?.presentAlert(with: error)
            self?.hideLoadingBar()
        }).disposed(by: disposeBag)
    }
    
}

extension BadNewWorkoutViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            getPlacesForCurrentLocation()
        case .denied, .restricted:
            self.hideLoadingBar()
            presentAlert(title: "Location Permission Required", message: "To check in a location, please enable the permission in settings.")
        case .notDetermined:
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

extension Bool {
    
    var toggled: Bool {
        return !self
    }
    
}

extension Array where Element == Place {
    
    func unique() -> [Place] {
        var seen: [String: Bool] = [:]
        return self.filter { seen.updateValue(true, forKey: $0.name) == nil }
    }
    
}

protocol OptionalParasite {
    associatedtype WrappedParasite
    
    func toArray() -> [WrappedParasite]
}

extension Optional: OptionalParasite {
    typealias WrappedParasite = Wrapped
    
    func toArray() -> [WrappedParasite] {
        return flatMap { [$0] } ?? []
    }
}

extension Sequence where Iterator.Element: OptionalParasite {
    func compacted() -> [Iterator.Element.WrappedParasite] {
        return flatMap { element in
            return element.toArray()
        }
    }
}