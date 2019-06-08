//
//  UpcomingCollectionViewCell.swift
//  GymRats
//
//  Created by Mack on 6/5/19.
//  Copyright © 2019 Mack Hasz. All rights reserved.
//

import UIKit

class UpcomingCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var userImageView: UserImageView!
    @IBOutlet weak var someText: UILabel!
    
    var user: User! {
        didSet {
            self.someText.text = user.fullName
            self.userImageView.skeletonLoad(avatarInfo: user)
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()

        someText.textColor = .black
        someText.font = .bigAndBlack
    }
}