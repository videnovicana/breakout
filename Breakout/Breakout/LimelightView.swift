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
        self.init(frame: rect)

        setEllipseShape()
    }

    let shapeLayer = CAShapeLayer()

    func setEllipseShape() {

        backgroundColor = UIColor.clear

        shapeLayer.path = UIBezierPath(ovalIn: bounds).cgPath
        shapeLayer.fillColor = Colors.rayColor.cgColor
        shapeLayer.opacity = 0.3

        layer.addSublayer(shapeLayer)
    }
}
