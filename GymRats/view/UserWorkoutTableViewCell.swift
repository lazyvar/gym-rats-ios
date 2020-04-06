//
//  UserWorkoutTableViewCell.swift
//  GymRats
//
//  Created by Mack Hasz on 2/5/19.
//  Copyright © 2019 Mack Hasz. All rights reserved.
//

import UIKit
import AvatarImageView
import RxSwift
import Kingfisher

class UserWorkoutTableViewCell: UITableViewCell {

    let disposeBag = DisposeBag()
    
    @IBOutlet weak var userImageView: UserImageView!
    @IBOutlet weak var fullNameLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()

        titleLabel.font = .body
        detailsLabel.font = .details
        fullNameLabel.font = .body
        
        titleLabel.isHidden = true
        detailsLabel.isHidden = true
        fullNameLabel.isHidden = true
        contentView.alpha = 1.0
        accessoryView = nil
    }
    
    var userWorkout: UserWorkout! {
        didSet {
            let user = userWorkout.user

            if let workout = userWorkout.workout {
                if workout.pictureUrl != nil {
                    userImageView.skeletonLoad(avatarInfo: workout)
                } else {
                    userImageView.load(avatarInfo: user)
                }
                
                titleLabel.isHidden = false
                detailsLabel.isHidden = false
                titleLabel.text = workout.title
                
                detailsLabel.attributedText = detailsLabeText()

                if let googlePlaceId = workout.googlePlaceId {
                    GService.getPlaceInformation(forPlaceId: googlePlaceId)
                        .subscribe {  [weak self] event in
                            guard let self = self else { return }
                            
                            if case let .next(val) = event {
                                UIView.transition (
                                    with: self.detailsLabel,
                                    duration: 0.2,
                                    options: .transitionCrossDissolve,
                                    animations: { [weak self] in
                                        self?.detailsLabel.attributedText = self?.detailsLabeText(including: val)
                                    }, completion: nil)
                            }
                        }.disposed(by: disposeBag)
                }
                
                let label = UILabel()
                label.text = workout.createdAt.challengeTime
                label.font = .details
                label.sizeToFit()
                
                accessoryView = label
            }
        }
    }
    
    var challenge: Challenge! {
        didSet {
            titleLabel.isHidden = false
            detailsLabel.isHidden = false
            userImageView.load(avatarInfo: challenge)
            titleLabel.text = challenge.name

            if challenge.isActive {
                detailsLabel.text = challenge.daysLeft
                accessoryType = .disclosureIndicator
            } else if challenge.isPast {
                detailsLabel.text = challenge.daysLeft
                accessoryType = .disclosureIndicator
            } else {
                detailsLabel.text = "Starts \(challenge.startDate.toFormat("MMMM d")) - Join using \(challenge.code)"
                contentView.alpha = 0.333
            }
        }
    }

    func configureForSleeping(user: Account, day: Date, allWorkouts: [Workout]) {
        userImageView.load(avatarInfo: user)

        titleLabel.isHidden = false
        detailsLabel.isHidden = false
        titleLabel.text = user.fullName

        let myWorkouts = allWorkouts.filter { $0.gymRatsUserId == user.id }
        let workoutsBeforeToday = myWorkouts.filter { $0.createdAt < day }
        let sorted = workoutsBeforeToday.sorted(by: { $0.createdAt < $1.createdAt })
        
        if let last = sorted.last {
            let differnece = abs(day.getInterval(toDate: last.createdAt, component: .day))
            
            if differnece == 1 {
                detailsLabel.text = "Active yesterday"
            } else {
                detailsLabel.text = "Active \(differnece) days ago"
            }
        } else {
            detailsLabel.text = "Has yet to workout"
        }
        
        let label = UILabel()
        label.text = "Zzz"
        label.font = .details
        label.sizeToFit()
        label.alpha = 0.333
        
        accessoryView = label
        contentView.alpha = 0.333
    }
    
    func configure(for user: Account, withNumberOfWorkouts numberOfWorkouts: Int) {
        userImageView.load(avatarInfo: user)
        
        fullNameLabel.isHidden = false
        fullNameLabel.text = user.fullName
        
        let label = UILabel()
        label.text = "\(numberOfWorkouts)"
        label.font = .details
        label.sizeToFit()
        label.textColor = .black
        
        accessoryView = label
    }
    
    private func detailsLabeText(including place: Place? = nil) -> NSAttributedString {
        let details = NSMutableAttributedString()
        
        if let profilePic = userWorkout.user.profilePictureUrl, let image = KingfisherManager.shared.cache.retrieveImageInMemoryCache(forKey: profilePic) ?? KingfisherManager.shared.cache.retrieveImageInDiskCache(forKey: profilePic) {
            let imageView = UIImageView(image: image)
            imageView.frame = CGRect(x: 0, y: 0, width: 14, height: 14)
            imageView.layer.cornerRadius = 7
            imageView.clipsToBounds = true
            imageView.contentMode = .scaleAspectFill
            
            let image = imageView.imageFromContext()
            
            let attachment = NSTextAttachment()
            attachment.image = image
            attachment.bounds = CGRect(x: 0, y: -3, width: 14, height: 14)
            
            details.append(NSAttributedString(attachment: attachment))
            details.append(NSAttributedString(string: "  "))
        }

        details.append(NSAttributedString(string: "\(userWorkout.user.fullName)"))
        
        if let place = place {
            details.append(NSAttributedString(string: " @ \(place.name)"))
        }
        
        return details
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        userImageView.imageView.image = nil
        titleLabel.isHidden = true
        detailsLabel.isHidden = true
        fullNameLabel.isHidden = true
        contentView.alpha = 1.0
        accessoryView = nil
    }
    
}

struct SeededRandomNumberGenerator: RandomNumberGenerator {
    init(seed: Int) {
        srand48(seed)
    }
    
    func next() -> UInt64 {
        return UInt64(drand48() * Double(UInt64.max))
    }
}

extension UIImageView {
    
    func imageFromContext() -> UIImage {
        UIGraphicsBeginImageContextWithOptions(bounds.size, isOpaque, 0.0)
        layer.render(in: UIGraphicsGetCurrentContext()!)
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return image!
    }

}