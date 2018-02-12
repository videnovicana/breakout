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

        setEllipseShapeAndRadialGradient()
        follow(point: point)
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

        newRotationAngle = theta

        newTransform = CATransform3DMakeRotation(theta, 0, 0, 1)

        let animation = CABasicAnimation(keyPath: "transform")
        animation.delegate = self

        let presentationLayer = layer.presentation()
        let currentTransform = presentationLayer?.transform

        animation.fromValue = currentTransform
        animation.toValue = newTransform
        animation.duration = Constants.spotlightTurnTime
        layer.add(animation, forKey: animation.keyPath)
    }

    var newRotationAngle: CGFloat?
    private var newTransform: CATransform3D?
}

extension SpotlightView: CAAnimationDelegate {

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {

        if flag, let basicAnimation = anim as? CABasicAnimation,
            basicAnimation.keyPath == "transform" {
            layer.transform = newTransform!
        }
    }
}
