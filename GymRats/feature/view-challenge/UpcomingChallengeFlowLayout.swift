//
//  UpcomingChallengeFlowLayout.swift
//  GymRats
//
//  Created by mack on 4/9/20.
//  Copyright © 2020 Mack Hasz. All rights reserved.
//

import Foundation
import UIKit

class UpcomingChallengeFlowLayout: UICollectionViewFlowLayout {
  override init() {
    super.init()
    
    let spacing: CGFloat = 20
    let sectionInsets = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
    let lineSpacing: CGFloat = spacing
    let interItemSpacing: CGFloat = spacing
    let width: CGFloat = UIScreen.main.bounds.width / 3 - interItemSpacing / 2 - sectionInsets.left
    let height: CGFloat = width + 30
    
    scrollDirection = .vertical
    itemSize = CGSize(width: width, height: height)
    minimumLineSpacing = lineSpacing
    minimumInteritemSpacing = interItemSpacing
    sectionInset = sectionInsets
    headerReferenceSize = CGSize(width: UIScreen.main.bounds.width, height: 0)
  }
  
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}
