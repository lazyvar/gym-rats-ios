//
//  WorkoutViewController.swift
//  GymRats
//
//  Created by mack on 4/8/20.
//  Copyright © 2020 Mack Hasz. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources
import Kingfisher
import RxKeyboard

typealias WorkoutSection = AnimatableSectionModel<Int, WorkoutRow>

class WorkoutViewController: BindableViewController {
  var workout: Workout

  private let viewModel = WorkoutViewModel()
  private let disposeBag = DisposeBag()
  private let challenge: Challenge?
  private let dismissPanGesture = UIPanGestureRecognizer()

  var isInteractivelyDismissing: Bool = false
  weak var transitionController: WorkoutPopComplexTransition?
  
  @IBOutlet private weak var tableView: UITableView! {
    didSet {
      tableView.backgroundColor = .clear
      tableView.separatorColor = .divider
      tableView.separatorInset = .zero
      tableView.clipsToBounds = false
      tableView.tableFooterView = UIView()
      tableView.showsVerticalScrollIndicator = false
      tableView.registerCellNibForClass(WorkoutDetailsCell.self)
      tableView.registerCellNibForClass(ImageViewCell.self)
      tableView.registerCellNibForClass(MapCell.self)
      tableView.registerCellNibForClass(WorkoutAccountCell.self)
      tableView.registerCellNibForClass(CommentCell.self)
      tableView.registerCellNibForClass(NewCommentCell.self)
    }
  }
  
  @IBOutlet private weak var bottomConstraint: NSLayoutConstraint!
  
  init(workout: Workout, challenge: Challenge?) {
    self.workout = workout
    self.challenge = challenge
    self.viewModel.configure(workout: workout, challenge: challenge)

    super.init(nibName: nil, bundle: nil)
  }
  
  required init?(coder aDecoder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private lazy var dataSource = RxTableViewSectionedAnimatedDataSource<WorkoutSection>(configureCell: { _, tableView, indexPath, row -> UITableViewCell in
    switch row {
    case .image(url: let url):
      return ImageViewCell.configure(tableView: tableView, indexPath: indexPath, imageURL: url)
    case .account(let workout):
      return WorkoutAccountCell.configure(tableView: tableView, indexPath: indexPath, workout: workout)
    case .details(let workout):
      return WorkoutDetailsCell.configure(tableView: tableView, indexPath: indexPath, workout: workout)
    case .location(placeID: let place):
      return MapCell.configure(tableView: tableView, indexPath: indexPath, placeID: place)
    case .comment(let comment, let onMenuTap):
      return CommentCell.configure(tableView: tableView, indexPath: indexPath, comment: comment, onMenuTap: onMenuTap)
    case .newComment(let onSubmit):
      return NewCommentCell.configure(tableView: tableView, indexPath: indexPath, account: GymRats.currentAccount, onSubmit: onSubmit)
    case .space:
      return UITableViewCell().apply {
        $0.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: .greatestFiniteMagnitude)
        $0.directionalLayoutMargins = .zero
        $0.backgroundColor = .clear
        $0.heightAnchor.constraint(equalToConstant: 50).isActive = true
        $0.selectionStyle = .none
      }
    }
  })
  
  override func bindViewModel() {
    viewModel.output.sections
      .do(onNext: { _ in self.hideLoadingBar() })
      .bind(to: tableView.rx.items(dataSource: dataSource))
      .disposed(by: disposeBag)

    viewModel.output.error
      .do(onNext: { _ in self.hideLoadingBar() })
      .flatMap { UIAlertController.present($0) }
      .ignore(disposedBy: disposeBag)

    viewModel.output.navigation
      .subscribe(onNext: { [weak self] (navigation, screen) in
        self?.navigate(navigation, to: screen.viewController)
      })
      .disposed(by: disposeBag)

    viewModel.output.presentCommentAlert
      .subscribe { [weak self] e in
        if let comment = e.element {
          self?.showCommentMenu(comment)
        }
      }
      .disposed(by: disposeBag)
    
    tableView.rx.itemSelected
      .do(onNext: { [weak self] indexPath in
        self?.tableView.deselectRow(at: indexPath, animated: true)
      })
      .bind(to: viewModel.input.tappedRow)
      .disposed(by: disposeBag)
    
    RxKeyboard.instance.visibleHeight
      .drive(onNext: { [tableView] keyboardVisibleHeight in
        tableView?.contentInset.bottom = keyboardVisibleHeight + 30
      })
      .disposed(by: disposeBag)
  }
  
  private var spookyView: UIView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    dismissPanGesture.addTarget(self, action: #selector(dismissPanGestureDidChange(_:)))
    dismissPanGesture.delegate = self

    tableView.addGestureRecognizer(self.dismissPanGesture)

    spookyView = SpookyView().apply {
      $0.translatesAutoresizingMaskIntoConstraints = false
      $0.isUserInteractionEnabled = false
    }

    view.insertSubview(spookyView, at: 0)

    let top = NSLayoutConstraint(
      item: spookyView!,
      attribute: .top,
      relatedBy: .equal,
      toItem: tableView,
      attribute: .top,
      multiplier: 1,
      constant: 0
    )

    view.addConstraint(top)

    spookyView.leadingAnchor.constraint(equalTo: tableView.leadingAnchor).isActive = true
    spookyView.trailingAnchor.constraint(equalTo: tableView.trailingAnchor).isActive = true

    let height = spookyView.constrainHeight(400)

    tableView.rx.contentOffset
      .map { -1 * $0.y }
      .bind(to: top.rx.constant)
      .disposed(by: disposeBag)

    tableView.rx.observe(CGSize.self, "contentSize")
      .map { ($0?.height ?? 0) - 50 }
      .bind(to: height.rx.constant)
      .disposed(by: disposeBag)
    
    navigationItem.largeTitleDisplayMode = .never
    
    let tapToHideKeyboard = UITapGestureRecognizer()
    tapToHideKeyboard.numberOfTapsRequired = 1
    tapToHideKeyboard.addTarget(self, action: #selector(hideKeyboard))
    tapToHideKeyboard.cancelsTouchesInView = false
    
    view.addGestureRecognizer(tapToHideKeyboard)

    let menu =  UIBarButtonItem (
      image: .moreHorizontal,
      style: .plain,
      target: self,
      action: #selector(showWorkoutMenu)
    )
    
    if let challenge = challenge {
      if Membership.State.owner(of: challenge) || workout.account.id == GymRats.currentAccount.id {
        navigationItem.rightBarButtonItem = menu
      }
    } else {
      navigationItem.rightBarButtonItem = menu
    }
    
    let ugh = UIView()
    ugh.backgroundColor = .background
    ugh.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 3000)
    
    view.addSubview(ugh)
    view.sendSubviewToBack(ugh)
    
    viewModel.input.viewDidLoad.trigger()
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    
    bottomConstraint.constant = (tabBarController?.tabBar.frame.height ?? 0) + view.safeAreaInsets.bottom
  }
  
  @objc private func hideKeyboard() {
    view.endEditing(true)
  }
  
  @objc private func dismissPanGestureDidChange(_ gesture: UIPanGestureRecognizer) {
    switch gesture.state {
    case .began:
      isInteractivelyDismissing = true
      navigationController?.popViewController(animated: true)
    case .cancelled, .failed, .ended:
      isInteractivelyDismissing = false
    case .changed, .possible:
      break
    @unknown default:
      break
    }

    transitionController?.didPanWith(gestureRecognizer: gesture)
  }
  
  private func showCommentMenu(_ comment: Comment) {
    let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    let delete = UIAlertAction(title: "Delete comment", style: .destructive) { [weak self] _ in
      let areYouSureAlert = UIAlertController(title: "Are you sure?", message: "This will permanently remove the comment.", preferredStyle: .alert)
      
      let delete = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
        guard let self = self else { return }
        
        self.showLoadingBar()
        self.viewModel.input.tappedDeleteComment.onNext(comment)
      }
      
      let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
      
      areYouSureAlert.addAction(delete)
      areYouSureAlert.addAction(cancel)
      
      self?.present(areYouSureAlert, animated: true, completion: nil)
    }
    
    let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    
    alert.addAction(delete)
    alert.addAction(cancel)
    
    self.present(alert, animated: true, completion: nil)
  }
  
  @objc private func showWorkoutMenu() {
    let edit = UIAlertAction(title: "Edit", style: .default) { _ in
      let viewController = CreateWorkoutViewController(workout: .right(self.workout))
      viewController.delegate = self
      
      self.presentInNav(viewController)
    }
    
    let deleteAction = UIAlertAction(title: "Remove workout", style: .destructive) { _ in
      let areYouSureAlert = UIAlertController(title: "Are you sure?", message: "You will not be able to recover a workout once it has been removed.", preferredStyle: .alert)
      
      let deleteAction = UIAlertAction(title: "Remove", style: .destructive) { _ in
        self.showLoadingBar()
      
        gymRatsAPI.deleteWorkout(self.workout)
          .subscribe(onNext: { [weak self] result in
            guard let self = self else { return }
            
            self.hideLoadingBar()
            
            switch result {
            case .success:
              self.navigationController?.popViewController(animated: true)
              NotificationCenter.default.post(name: .workoutDeleted, object: self.workout)
            case .failure(let error):
              self.presentAlert(with: error)
            }
          })
          .disposed(by: self.disposeBag)
      }
      
      let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
      
      areYouSureAlert.addAction(deleteAction)
      areYouSureAlert.addAction(cancelAction)
      
      self.present(areYouSureAlert, animated: true, completion: nil)
    }
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    let alertViewController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    
    if workout.account.id == GymRats.currentAccount.id {
      alertViewController.addAction(edit)
    }
    
    alertViewController.addAction(deleteAction)
    alertViewController.addAction(cancelAction)

    self.present(alertViewController, animated: true, completion: nil)
  }
}

extension WorkoutViewController: UIGestureRecognizerDelegate {
  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
    return true
  }

  func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
  
  func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}

extension WorkoutViewController {
  var bigFrame: CGRect {
    let statusBar = UIApplication.shared.statusBarFrame.height
    let navigationHeight = (navigationController?.navigationBar.frame.height ?? 0)
    let viewWidth = UIScreen.main.bounds.width - 40

    let imageHeight: CGFloat = {
      guard let photoURL = workout.photoUrl else { return .zero }
      
      if let image = KingfisherManager.shared.cache.retrieveImageInMemoryCache(forKey: photoURL) ?? KingfisherManager.shared.cache.retrieveImageInDiskCache(forKey: photoURL) {
        return (image.size.height / image.size.width) * viewWidth
      } else {
        return viewWidth
      }
    }()
    
    return CGRect(x: 20, y: statusBar + navigationHeight + 5, width: viewWidth, height: imageHeight)
  }
  
  func transitionWillStart(push: Bool) {
    if push {
      tableView.alpha = 0
      spookyView.alpha = 0
    } else {
      UIView.animate(withDuration: 0.35) {
        self.tableView.alpha = 1
      }
    }
  }
  
  func transitionDidEnd(push: Bool) {
    if push {
      UIView.animate(withDuration: 0.10) {
        self.tableView.alpha = 1
        self.spookyView.alpha = 1
      }
    }
  }
}

extension WorkoutViewController: CreatedWorkoutDelegate {
  func createWorkoutController(_ createWorkoutController: CreateWorkoutViewController, created workout: Workout) {
    NotificationCenter.default.post(name: .workoutDeleted, object: self.workout)
    createWorkoutController.dismissSelf()
    self.workout = workout
    self.viewModel.configure(workout: workout, challenge: self.challenge)
    self.viewModel.input.updatedWorkout.trigger()
  }
}
