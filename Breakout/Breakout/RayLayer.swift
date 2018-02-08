//
//  RayLayer.swift
//  Breakout
//
//  Created by ana videnovic on 2/7/18.
//  Copyright © 2018 ana videnovic. All rights reserved.
//

import UIKit

class RayLayer: CAGradientLayer {

    convenience init(in rect: CGRect, vertices: [CGPoint]) {
        self.init()

        self.frame = rect
        self.colors = [Colors.rayColor.cgColor, UIColor.clear.cgColor]
        self.locations = [0, 0.6]
        self.opacity = 1

        setShape(using: vertices)
    }

    func setShape(using vertices: [CGPoint]) {
        guard vertices.count == 4 else {
            return
        }

        let path = UIBezierPath()
        path.move(to: vertices[0])
        path.addLine(to: vertices[1])
        path.addLine(to: vertices[2])
        path.addLine(to: vertices[3])
        path.close()

        let shapeLayer = CAShapeLayer()
        shapeLayer.path = path.cgPath

        self.mask = shapeLayer
    }
}
