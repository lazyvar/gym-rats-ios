//
//  UIImage+Assets.swift
//  GymRats
//
//  Created by mack on 3/11/20.
//  Copyright © 2020 Mack Hasz. All rights reserved.
//

import UIKit

extension UIImage {
  static let moreHorizontal     = UIImage(named: "more-horizontal")!
  static let chat               = UIImage(named: "chat")!
  static let chatUnread         = UIImage(named: "chat-unread")!
  static let award              = UIImage(named: "award")!
  static let activityLargeWhite = UIImage(named: "activity-large-white")!
  static let activity           = UIImage(named: "activity")!
  static let flag               = UIImage(named: "flag")!
  static let plusCircle         = UIImage(named: "plus-circle")!
  static let play               = UIImage(named: "play")!
  static let gear               = UIImage(named: "gear")!
  static let info               = UIImage(named: "info")!
  static let chevronLeft        = UIImage(named: "chevron-left")!
  static let chevronRight       = UIImage(named: "chevron-right")!
  static let eyeOn              = UIImage(named: "eye-on")!
  static let eyeOff             = UIImage(named: "eye-off")!
  static let nameLight          = UIImage(named: "name-light")!
  static let checkLight         = UIImage(named: "check-light")!
  static let mailLight          = UIImage(named: "mail-light")!
  static let lockLight          = UIImage(named: "lock-light")!
  static let nameDark           = UIImage(named: "name-dark")!
  static let checkDark          = UIImage(named: "check-dark")!
  static let mailDark           = UIImage(named: "mail-dark")!
  static let lockDark           = UIImage(named: "lock-dark")!
  static let heart              = UIImage(named: "heart")!
  static let proPic             = UIImage(named: "pro-pic")!
  static let close              = UIImage(named: "close")!
  static let menu               = UIImage(named: "menu")!
  static let checked            = UIImage(named: "checked")!
  static let notChecked         = UIImage(named: "not-checked")!
  static let big                = UIImage(named: "big")!
  static let list               = UIImage(named: "list")!
  static let clock              = UIImage(named: "clock")!
  static let plus               = UIImage(named: "plus")!
  static let code               = UIImage(named: "code")!
  static let externalLink       = UIImage(named: "external-link")!
  static let people             = UIImage(named: "people")!
  static let clipboard          = UIImage(named: "clipboard")!
  static let checkTemplate      = UIImage(named: "check")!
  static let star               = UIImage(named: "star")!
  static let pencil             = UIImage(named: "pencil")!
  static let cal                = UIImage(named: "cal")!
  static let smallAppleHealth   = UIImage(named: "small-apple-health")!
  static let map                = UIImage(named: "map")!
  static let help               = UIImage(named: "help")!
  static let messenger          = UIImage(named: "messenger")!
  static let mailTemplate       = UIImage(named: "mail-template")!
  static let link               = UIImage(named: "link")!
  static let expand             = UIImage(named: "expand")!
  static let soundOn            = UIImage(named: "sound")!
  static let muted              = UIImage(named: "muted")!
  static let flashOff           = UIImage(named: "flash-off")!
  static let flashOn            = UIImage(named: "flash-on")!
  static let flashAuto          = UIImage(named: "flash-auto")!
  static let reverse            = UIImage(named: "reverse")!
  static let icon               = UIImage(named: "Icon")!
  static let snap               = UIImage(named: "snap")!
  static let videoSnap          = UIImage(named: "video-snap")!
  static let videoRecording     = UIImage(named: "video-recording")!
  static let photoLibrary       = UIImage(named: "photo-library")!
  
  static var name: UIImage {
    switch UIDevice.contentMode {
    case .light: return .nameLight
    case .dark: return .nameDark
    }
  }

  static var check: UIImage {
    switch UIDevice.contentMode {
    case .light: return .checkLight
    case .dark: return .checkDark
    }
  }

  static var mail: UIImage {
    switch UIDevice.contentMode {
    case .light: return .mailLight
    case .dark: return .mailDark
    }
  }

  static var lock: UIImage {
    switch UIDevice.contentMode {
    case .light: return .lockLight
    case .dark: return .lockDark
    }
  }
}
