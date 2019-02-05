//
//  UIView+Extension.swift
//  GymRats
//
//  Created by Mack Hasz on 2/4/19.
//  Copyright © 2019 Mack Hasz. All rights reserved.
//

import Foundation
import UIKit

extension UIView {
    
    func center(in view: UIView, x: CGFloat = 0, y: CGFloat = 0) {
        horizontallyCenter(in: view, x: x)
        verticallyCenter(in: view, y: y)
    }
    
    @discardableResult func horizontallyCenter(in view: UIView, x: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint (
            item: self,
            attribute: .centerX,
            relatedBy: .equal,
            toItem: view,
            attribute: .centerX,
            multiplier: 1,
            constant: x
        )

        view.addConstraint(constraint)
        
        return constraint
    }
    
    @discardableResult func verticallyCenter(in view: UIView, y: CGFloat = 0) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint (
            item: self,
            attribute: .centerY,
            relatedBy: .equal,
            toItem: view,
            attribute: .centerY,
            multiplier: 1,
            constant: y
        )
        
        view.addConstraint(constraint)

        return constraint
    }
    
    @discardableResult func constrainWidth(_ width: CGFloat) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint (
            item: self,
            attribute: .width,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute, multiplier: 1, constant: width
        )
        
        constraint.isActive = true
        
        return constraint
    }
    
    @discardableResult func constrainHeight(_ height: CGFloat) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint (
            item: self,
            attribute: .height,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1,
            constant: height
        )
        
        constraint.isActive = true
        
        return constraint
    }
    
}
