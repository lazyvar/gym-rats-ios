//
//  UpcomingChallengeHeaderView.swift
//  GymRats
//
//  Created by mack on 4/9/20.
//  Copyright © 2020 Mack Hasz. All rights reserved.
//

import UIKit

class UpcomingChallengeHeaderView: UICollectionReusableView {
  @IBOutlet private weak var bannerImageView: UIImageView! {
    didSet {
      bannerImageView.contentMode = .scaleAspectFill
      bannerImageView.clipsToBounds = true
      bannerImageView.layer.cornerRadius = 4
      bannerImageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
  }
  
  @IBOutlet private weak var titleLabel: UILabel! {
    didSet {
      titleLabel.textColor = .primaryText
      titleLabel.font = .h4Bold
    }
  }
  
  @IBOutlet private weak var calendarImageView: UIImageView! {
    didSet {
      calendarImageView.tintColor = .primaryText
    }
  }
  
  @IBOutlet private weak var clockImageView: UIImageView! {
    didSet {
      clockImageView.tintColor = .primaryText
    }
  }
  
  @IBOutlet private weak var durationLabel: UILabel! {
    didSet {
      durationLabel.textColor = .primaryText
      durationLabel.font = .body
    }
  }
  
  @IBOutlet private weak var startsLabel: UILabel! {
     didSet {
       startsLabel.textColor = .primaryText
       startsLabel.font = .body
     }
   }
  
  @IBOutlet private weak var codeImageView: UIImageView! {
    didSet {
      codeImageView.tintColor = .primaryText
    }
  }
  
  @IBOutlet private weak var codeLabel: UILabel! {
    didSet {
      codeLabel.textColor = .primaryText
      codeLabel.font = .body
    }
  }
  
  func configure(_ challenge: Challenge) {
    let date: String = {
      if challenge.startDate.isToday {
        return "today"
      } else if challenge.startDate.isYesterday {
        return "yesterday"
      } else if challenge.startDate.isTomorrow {
        return "tomorrow"
      } else {
        return challenge.startDate.toFormat("MMMM d")
      }
    }()

    durationLabel.text = "Lasts \(challenge.days.count) days"
    startsLabel.text = "Starts \(date)"
    codeLabel.text = challenge.code
    
    if let photo = challenge.profilePictureUrl, let url = URL(string: photo) {
      bannerImageView.kf.setImage(with: url, options: [.transition(.fade(0.2))])
    } else {
      bannerImageView.isHidden = true
    }
  }
}
