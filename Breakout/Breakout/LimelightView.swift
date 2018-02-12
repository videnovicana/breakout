//
//  limelightView.swift
//  Breakout
//
//  Created by ana videnovic on 2/8/18.
//  Copyright © 2018 ana videnovic. All rights reserved.
//

import UIKit

class LimelightView: UIView {

    convenience init(ellipseIn rect: CGRect) {
        self.init()

        setEllipseShape(in: rect)
    }

    let shapeLayer = CAShapeLayer()

    func setEllipseShape(in rect: CGRect) {
        if self.frame.size != rect.size {
            self.frame = rect
            setEllipseShape()
            animateLimelightAppearance(in: rect)
        }
    }

    func setEllipseShape() {

        backgroundColor = UIColor.clear

        shapeLayer.path = UIBezierPath(ovalIn: bounds).cgPath
        shapeLayer.fillColor = Colors.rayColor.cgColor
        shapeLayer.opacity = 0.3

        layer.addSublayer(shapeLayer)
    }

    func moveCenterAlongXAxisBy(dx: CGFloat) {
        UIView.animate(withDuration: Constants.spotlightTurnTime) {
            self.center.x += dx
        }
    }

    func animateLimelightAppearance(in rect: CGRect) {
        let startingYOffset: CGFloat = 100
        center.y += startingYOffset

        UIView.animate(withDuration: Constants.spotlightTurnTime) {
            self.center.y -= startingYOffset
        }
    }
}
