//
//  RadialGradientLayer.swift
//  Breakout
//
//  Created by ana videnovic on 2/2/18.
//  Copyright © 2018 ana videnovic. All rights reserved.
//

import UIKit

class RadialGradientLayer: CALayer {

    var radius: CGFloat = 100.0 { didSet { setNeedsDisplay() } }

    var colors: [UIColor] = [UIColor.white, UIColor.yellow] { didSet { setNeedsDisplay() } }

    var cgColors: [CGColor] {
        return colors.map { $0.cgColor }
    }

    override func draw(in ctx: CGContext) {

        ctx.saveGState()

        if let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: cgColors as CFArray,
            locations: [0.0, 1.0]
        ) {
            ctx.drawRadialGradient(gradient,
                startCenter: bounds.mid, startRadius: 0.0,
                endCenter: bounds.mid, endRadius: radius,
                options: []
            )
        }
    }
}
