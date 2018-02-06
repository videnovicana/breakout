//
//  SpotlightView.swift
//  Breakout
//
//  Created by ana videnovic on 1/31/18.
//  Copyright © 2018 ana videnovic. All rights reserved.
//

import UIKit

class SpotlightView: UIView {

    convenience init(ellipseIn rect: CGRect, following point: CGPoint) {
        self.init(frame: rect)

        follow(point: point)
        setEllipseShapeAndRadialGradient()
    }

    func setEllipseShapeAndRadialGradient() {

        backgroundColor = UIColor.clear

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = UIBezierPath(ovalIn: bounds).cgPath

        let gradientLayer = RadialGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = Colors.spotlightColors
        gradientLayer.mask = shapeLayer

        layer.addSublayer(gradientLayer)
    }

    func follow(point pointToFollow: CGPoint) {
        let c = center.distanceTo(pointToFollow)
        let a = center.x - pointToFollow.x
        let theta = asin(a/c)

        transform = CGAffineTransform(rotationAngle: theta)
    }
}
