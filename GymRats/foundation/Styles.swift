//
//  Styles.swift
//  GymRats
//
//  Created by Mack Hasz on 2/4/19.
//  Copyright © 2019 Mack Hasz. All rights reserved.
//

import UIKit

func roundedStyle(cornerRadius: CGFloat = 4) -> ((UIView) -> UIView) {
    return { view in
        view.clipsToBounds = true
        view.layer.masksToBounds = true
        view.layer.cornerRadius = cornerRadius
        view.layer.borderWidth = 0
        
        return view
    }
}

func baseButtonStyle() -> (UIButton) -> (UIButton) {
    return { button in
        _ = roundedStyle()(button)
        button.contentEdgeInsets = UIEdgeInsets(top: 15, left: 15, bottom: 15, right: 15)
        button.titleLabel?.font = .h4
        
        return button
    }
}

extension UIButton {
    
    static func primary(text: String) -> UIButton {
        var button = UIButton()
        button.setTitle(text, for: .normal)
        button = baseButtonStyle()(button)
        button.setTitleColor(UIColor.newWhite, for: .normal)
        button.setTitleColor(UIColor.newWhite, for: .highlighted)
        button.setTitleColor(UIColor.gray, for: .disabled)
        button.setBackgroundImage(.init(color: .greenSea), for: .normal)
        button.setBackgroundImage(.init(color: UIColor.greenSea.darker), for: .highlighted)
        button.setBackgroundImage(.init(color: UIColor.greenSea.darker), for: .disabled)
        
        return button
    }
    
    static func secondary(text: String) -> UIButton {
        var button = UIButton()
        button = baseButtonStyle()(button)
        button.setTitle(text, for: .normal)
        button.setTitleColor(UIColor.primaryText, for: .normal)
        button.setTitleColor(UIColor.primaryText.darker, for: .highlighted)
        button.setBackgroundImage(.init(color: .foreground), for: .normal)
        button.setBackgroundImage(.init(color: UIColor.foreground.darker), for: .highlighted)

        return button
    }

}

extension UIFont {
    static let body = UIFont(name: "SFProRounded-Regular", size: 14)!
    static let bodyBold = UIFont(name: "SFProRounded-Bold", size: 14)!
    static let details = UIFont(name: "SFProRounded-Regular", size: 12)!
    static let detailsBold = UIFont(name: "SFProRounded-Bold", size: 12)!
    static let bigAndBlack = UIFont(name: "Lato-Black", size: 16)!
    static let menu = UIFont(name: "Lato-Black", size: 18)!
    static let h1 = UIFont(name: "SFProRounded-Regular", size: 32)!
    static let h1Bold = UIFont(name: "SFProRounded-Bold", size: 32)!
    static let h2 = UIFont(name: "SFProRounded-Regular", size: 24)!
    static let h3 = UIFont(name: "SFProRounded-Regular", size: 20)!
    static let h4 = UIFont(name: "SFProRounded-Regular", size: 18)!
    static let bold = UIFont(name: "SFProRounded-Bold", size: 14)!
    
    static func proRoundedRegular(size: CGFloat) -> UIFont {
        return UIFont(name: "SFProRounded-Regular", size: size)!
    }
    static func proRoundedBold(size: CGFloat) -> UIFont {
        return UIFont(name: "SFProRounded-Bold", size: size)!
    }
}
