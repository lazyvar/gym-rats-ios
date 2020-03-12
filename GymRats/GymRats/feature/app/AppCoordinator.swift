//
//  AppCoordinator.swift
//  GymRats
//
//  Created by Mack Hasz on 2/4/19.
//  Copyright © 2019 Mack Hasz. All rights reserved.
//

import Foundation
import RxSwift
import MMDrawerController
import GooglePlaces
import Firebase
import UserNotifications
import ESTabBarController_swift
import MessageUI
import Kingfisher

struct UserWorkout {
  let user: Account
  let workout: Workout?
}

class AppCoordinator: NSObject, UNUserNotificationCenterDelegate {
    
    let window: UIWindow
    let application: UIApplication
    
    var currentUser: Account!
    var drawer: MMDrawerController!
    
    var coldStartNotification: [AnyHashable: Any]?
    
    let disposeBag = DisposeBag()
    
    init(window: UIWindow, application: UIApplication) {
        self.window = window
        self.application = application
    }
    
    func start() {
      
    }
    
    func userNotificationCenter (
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        handleNotification(userInfo: notification.request.content.userInfo, completionHandler: completionHandler)
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        if GymRatsApp.coordinator.coldStartNotification == nil {
            handleNotification(userInfo: response.notification.request.content.userInfo)
        }
    }
    
    private func registerForNotifications(on application: UIApplication) {
        // check device notifications
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }
    }
    
    func handleNotification(userInfo: [AnyHashable: Any], completionHandler: ((UNNotificationPresentationOptions) -> Void)? = nil) {
        let aps: ApplePushServiceObject
        do {
            aps = try ApplePushServiceObject(from: userInfo)
        } catch let error {
            print(error)
            return
        }
        
        guard GymRats.currentAccount != nil else { return }
        
        switch aps.gr.notificationType {
        case .comment:
            guard let comment = aps.gr.comment else { return }
            
            if let openWorkoutId = openWorkoutId, openWorkoutId == comment.workoutId {
                NotificationCenter.default.post(name: .commentNotification, object: aps.gr.comment)
                completionHandler?(.sound)
            } else {
                if let completionHandler = completionHandler {
                    completionHandler(.alert)
                } else {
                    guard let user = aps.gr.user, let challenge = aps.gr.challenge, let workout = aps.gr.workout else { return }
                    
                    let workoutViewController = WorkoutViewController(user: user, workout: workout, challenge: challenge)
                    workoutViewController.hidesBottomBarWhenPushed = true

                    if let nav = GymRatsApp.coordinator.drawer.centerViewController as? UINavigationController {
                        nav.pushViewController(workoutViewController, animated: true)
                    } else if let tabBar = tabBarViewController {
                        if let nav = tabBar.viewControllers?[safe: 1] as? UINavigationController {
                            nav.pushViewController(workoutViewController, animated: true)
                        }
                    }
                }
            }
        case .chatMessage:
            guard let chatMessage = aps.gr.chatMessage else { return }

            if let openChallengeChatId = openChallengeChatId, openChallengeChatId == chatMessage.challengeId {
                NotificationCenter.default.post(name: .chatNotification, object: aps.gr.chatMessage)
                completionHandler?(.sound)
            } else {
                if let completionHandler = completionHandler {
                    completionHandler(.alert)
                } else {
                    guard let challenge = aps.gr.challenge else { return }
                    
                    let chatViewController = ChatViewController(challenge: challenge)
                    chatViewController.hidesBottomBarWhenPushed = true
                    
                    if let nav = GymRatsApp.coordinator.drawer.centerViewController as? UINavigationController {
                        nav.pushViewController(chatViewController, animated: true)
                    } else if let tabBar = tabBarViewController {
                        if let nav = tabBar.viewControllers?[safe: 1] as? UINavigationController {
                            nav.pushViewController(chatViewController, animated: true)
                        }
                    }
                }
            }
        }
    }
    
    var openWorkoutId: Int?
    var openChallengeChatId: Int?

    var menu: MenuViewController!
    weak var tabBarViewController: ESTabBarController?
    
    func login(user: Account) {
        currentUser = user
        menu = MenuViewController()
        
        let home = HomeViewController()
        let centerViewController = UINavigationController(rootViewController: home)
        
        drawer = MMDrawerController(center: centerViewController, leftDrawerViewController: menu)
        drawer.view.backgroundColor = .background
        drawer.showsShadow = false
        drawer.maximumLeftDrawerWidth = MenuViewController.menuWidth
        drawer.centerHiddenInteractionMode = .full
        drawer.openDrawerGestureModeMask = [.all]
        drawer.closeDrawerGestureModeMask = [.all]
        drawer.setDrawerVisualStateBlock(MMDrawerVisualState.parallaxVisualStateBlock(withParallaxFactor: 2))
        drawer.setGestureCompletionBlock { drawer, _ in
            guard let drawer = drawer else { return }
            
            if drawer.openSide == .none {
                drawer.rightDrawerViewController = nil
            }
        }
        
        Track.currentUser()
        window.rootViewController = drawer
    }
    
    @objc func toggleMenu() {
        if drawer.openSide == .left {
            drawer.closeDrawer(animated: true, completion: nil)
        } else {
            drawer.open(.left, animated: true, completion: nil)
        }
    }
    
    func replaceCenterInTab(with viewController: ChallengeViewController, challenge: Challenge) {
        let centerViewController = center(with: viewController, challenge: challenge)

        drawer.setCenterView(centerViewController, withCloseAnimation: true, completion: { _ in
            self.tabBarViewController?.didHijackHandler = { a, b, index in
                if index == 0 {
                    self.presentStandings()
                } else if index == 1 {
                    self.openNewWorkout()
                } else if index == 2 {
                    self.openChat()
                }
            }
        })
        
        self.artistViewController = viewController
    }
    
    var artistViewController: ChallengeViewController?
    
    func center(with artistViewController: UIViewController, challenge: Challenge) -> UIViewController {
        let tabBarController = ESTabBarController()
        tabBarController.shouldHijackHandler = { _, _, _ in return true }
        tabBarController.tabBar.isTranslucent = false
        tabBarController.tabBar.shadowImage = UIImage()
        tabBarController.tabBar.backgroundImage = UIImage()
        
        let v1 = UIViewController()
        let v2 = artistViewController.inNav()
        let v3 = UIViewController()
        v3.view.backgroundColor = .peterRiver
        
        let standings = UIImage(named: "standings")!.withRenderingMode(.alwaysOriginal)
        let chat = UIImage(named: "chat-gray")!.withRenderingMode(.alwaysOriginal)
        let plus = UIImage(named: "activity-large-white")!
        
        v1.tabBarItem = UITabBarItem(title: nil, image: standings, selectedImage: standings)
        v2.tabBarItem = ESTabBarItem.init(BigContentView(), title: nil, image: plus, selectedImage: plus)
        v3.tabBarItem = UITabBarItem(title: nil, image: chat, selectedImage: chat)
        v3.tabBarItem?.badgeColor = .brand
        
        tabBarController.viewControllers = [v1, v2, v3]
        tabBarController.selectedIndex = 1
        tabBarController.tabBar.layer.shadowOffset = CGSize(width: 0, height: 0)
        tabBarController.tabBar.layer.shadowRadius = 10
        tabBarController.tabBar.layer.shadowColor = UIColor.shadow.cgColor
        tabBarController.tabBar.layer.shadowOpacity = 0.5
        tabBarController.tabBar.barTintColor = .background
        
        let pxwhiteThing = UIView(frame: CGRect(x: 0, y: -1, width: tabBarController.tabBar.frame.width, height: 1))
        pxwhiteThing.backgroundColor = .background
        tabBarController.tabBar.addSubview(pxwhiteThing)
        tabBarController.tabBar.sendSubviewToBack(pxwhiteThing)
        
        self.tabBarViewController = tabBarController
        
        return tabBarController
    }
    
    func presentStandings() {
        guard let nav = tabBarViewController?.viewControllers?[safe: 1] as? UINavigationController else { return }
        guard let artist = nav.viewControllers.last as? ChallengeViewController else { return }
        
//        let stats = ChallengeStatsViewController(challenge: artist.challenge, users: artist.users, workouts: artist.workouts)
//        
//        artist.push(stats)
    }
    
    func centerActiveOrUpcomingChallenge(_ challenge: Challenge) {
        if challenge.isActive {
            // replaceCenterInTab(with: ChallengeViewController(challenge: challenge), challenge: challenge)
        } else if challenge.isUpcoming {
            let upcomingViewController = UpcomingChallengeViewController(challenge: challenge).inNav()
            GymRatsApp.coordinator.drawer.setCenterView(upcomingViewController, withCloseAnimation: true, completion: nil)
        }
    }
    
    func openNewWorkout() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()

        let logWorkoutModal = LogWorkoutModalViewController() { image in
            let createWorkoutViewController = BadNewWorkoutViewController(workoutImage: image)
            createWorkoutViewController.delegate = self
            
            self.tabBarViewController?.present(createWorkoutViewController.inNav(), animated: true, completion: nil)
        }
        
        tabBarViewController?.presentPanModal(logWorkoutModal)
    }
    
    func pushUserProfile() {
        let profile = ProfileViewController(user: GymRats.currentAccount, challenge: nil)

        let gear = UIImage(named: "gear")!.withRenderingMode(.alwaysTemplate)
        let gearItem = UIBarButtonItem(image: gear, style: .plain, target: profile, action: #selector(ProfileViewController.transitionToSettings))
        gearItem.tintColor = .lightGray
        
        profile.navigationItem.rightBarButtonItem = gearItem
        
        artistViewController?.push(profile)
    }

    var chatItem: UITabBarItem? {
        return tabBarViewController?.tabBar.items?[safe: 2]
    }
    
    @objc func refreshChatIcon() {
//        guard let challenge = artistViewController?.challenge else { return }
        
//        gymRatsAPI.getUnreadChats(for: challenge)
//            .subscribe { event in
//                switch event {
//                case .next(let chats):
//                  guard let chats = chats.object else { return }
//                    if chats.isEmpty {
//                        self.chatItem?.badgeValue = nil
//                    } else {
//                        self.chatItem?.badgeValue = String(chats.count)
//                    }
//                default: break
//                }
//            }.disposed(by: disposeBag)
    }
    
    func openChat() {
        guard let nav = tabBarViewController?.viewControllers?[safe: 1] as? UINavigationController else {
            return
        }
        
        guard let artist = nav.viewControllers.last as? ChallengeViewController else { return }
        
//        let chat = ChatViewController(challenge: artist.challenge)
//
//        artist.push(chat)
    }
    
    func proPicImage(_ image: UIImage) -> UIImage {
        let imageView = UIImageView(frame: .init(x: 0, y: 0, width: 27, height: 27))
        imageView.layer.cornerRadius = 13.5
        imageView.image = image
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        
        let ringView = RingView(frame: .zero, ringWidth: 0.5, ringColor: UIColor.black.withAlphaComponent(0.1))
        
        imageView.addSubview(ringView)
        
        let frame = imageView.frame
        let scale: CGFloat = 1.16
        let newWidth = frame.width * scale
        let newHeight = frame.height * scale
        
        let diffY = newWidth - frame.width
        let diffX = newHeight - frame.height
        
        ringView.frame = CGRect(x: -diffX/2, y: -diffY/2, width: newWidth, height: newHeight)
        
        return imageView.imageFromContext().withRenderingMode(.alwaysOriginal)
    }
    
    func updateUser(_ user: Account) {
        self.currentUser = user
        
        Track.currentUser()
        
        NotificationCenter.default.post(name: .updatedCurrentUser, object: user)
        
        // update pic on tab
        if let proPicUrl = user.pictureUrl, let url = URL(string: proPicUrl) {
            KingfisherManager.shared.retrieveImage(with: url, options: nil, progressBlock: nil) { image, _, _, _ in
                if let image = image {
                    let proPicImage = self.proPicImage(image)
                    NotificationCenter.default.post(name: .updatedCurrentUserPic, object: image)
                    if let tabBar = self.tabBarViewController, let first = tabBar.viewControllers?.first {
                        first.tabBarItem = UITabBarItem(title: nil, image: proPicImage, selectedImage: proPicImage)
                    }
                }
            }
        }
        
        if let artist = artistViewController {
            // artist.fetchUserWorkouts()
        }

        switch Keychain.gymRats.storeObject(user, forKey: .currentUser) {
        case .success:
            print("Woohoo!")
        case .error(let error):
            print("Bummer! \(error.description)")
        }
    }
    
    func logout() {
        gymRatsAPI.deleteDevice()
            .subscribe { _ in
                let nav = UINavigationController(rootViewController: WelcomeViewController())
                nav.navigationBar.turnSolidWhiteSlightShadow()
                
                self.window.rootViewController = nav
                self.currentUser = nil

                switch Keychain.gymRats.deleteObject(withKey: .currentUser) {
                case .success:
                    print("Woohoo!")
                case .error(let error):
                    print("Bummer! \(error.description)")
                }
            }.disposed(by: disposeBag)
    }
    
    func loadCurrentUser() -> Account? {
        switch Keychain.gymRats.retrieveObject(forKey: .currentUser) {
        case .success(let user):
            return user
        case .error(let error):
            print("Bummer! \(error.description)")
            return nil
        }
    }
    
    var artistVc: ChallengeViewController? {
        if let vc = (GymRatsApp.coordinator.drawer?.centerViewController as? UITabBarController)?.viewControllers?[safe: 1] as? UINavigationController {
            if let vc = vc.viewControllers[safe: 0] as? ChallengeViewController {
                return vc
            }
        }
        
        return nil
    }
}

extension AppCoordinator: NewWorkoutDelegate {
    
    func newWorkoutController(_ newWorkoutController: BadNewWorkoutViewController, created workouts: [Workout]) {
        newWorkoutController.dismissSelf()
        // self.artistVc?.fetchUserWorkouts()
    }
    
}

extension Keychain {
    static var gymRats = Keychain(group: nil)
}

extension Keychain.Key where Object == Account {
    static var currentUser: Keychain.Key<Account> {
        return Keychain.Key<Account>(rawValue: "currentUser", synchronize: true)
    }
}


extension NSNotification.Name {
    static let updatedCurrentUser = NSNotification.Name(rawValue: "GRCurrentUserUpdated")
    static let updatedCurrentUserPic = NSNotification.Name(rawValue: "GRCurrentUserUpdatedPic")
}

extension UIWindow {
    func topmostViewController() -> UIViewController {
      func recurse(_ viewController: UIViewController) -> UIViewController {
        switch viewController {
          case let tabBarViewController as UITabBarController:
            return recurse(tabBarViewController.selectedViewController ?? tabBarViewController)
          case let navigationViewController as UINavigationController:
            return recurse(navigationViewController.viewControllers.last ?? navigationViewController)
          default:
            if let presentedViewController = viewController.presentedViewController, !presentedViewController.isBeingDismissed {
              return recurse(presentedViewController)
            } else {
              return viewController
            }
        }
      }
      
      return recurse(rootViewController!)
    }
}

extension UIViewController {
  static func topmost(for window: UIWindow = UIApplication.shared.keyWindow!) -> UIViewController {
    return window.topmostViewController()
  }
}
