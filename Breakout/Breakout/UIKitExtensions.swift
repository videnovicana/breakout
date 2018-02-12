//
//  UIKitExtensions.swift
//  Breakout
//
//  Created by ana videnovic on 10/20/17.
//  Copyright © 2017 ana videnovic. All rights reserved.
//

import UIKit

extension CGFloat {
    static func random(max: Int) -> CGFloat {
        return CGFloat(arc4random() % UInt32(max))
    }
    
    static func random(in range: Range<CGFloat>) -> CGFloat {
        return CGFloat(arc4random())/CGFloat(UInt32.max) * (range.upperBound-range.lowerBound) + range.lowerBound
    }
}

extension CGRect {
    var mid: CGPoint { return CGPoint(x: midX, y: midY) }
    var upperLeft: CGPoint { return CGPoint(x: minX, y: minY) }
    var lowerLeft: CGPoint { return CGPoint(x: minX, y: maxY) }
    var upperRight: CGPoint { return CGPoint(x: maxX, y: minY) }
    var lowerRight: CGPoint { return CGPoint(x: maxX, y: maxY) }
    var midLeft: CGPoint { return CGPoint(x: minX, y: midY) }
    var midRight: CGPoint { return CGPoint(x: maxX, y: midY) }

    init(center: CGPoint, size: CGSize) {
        let upperLeft = CGPoint(x: center.x-size.width/2, y: center.y-size.height/2)
        self.init(origin: upperLeft, size: size)
    }
}

extension CGPoint {
    func distanceTo(_ point: CGPoint) -> CGFloat {
        let dx = self.x - point.x
        let dy = self.y - point.y
        return sqrt(dx*dx + dy*dy)
    }

    func rotated(by angle: CGFloat, around center: CGPoint) -> CGPoint {
        let translationTransform = CGAffineTransform(translationX: -center.x, y: -center.y)
        let rotationTransform = CGAffineTransform(rotationAngle: angle)
        let completeTransform = (translationTransform.concatenating(rotationTransform)).concatenating(translationTransform.inverted())
        return self.applying(completeTransform)
    }
}

extension CGSize {
    func scaled(by factor: CGFloat) -> CGSize {
        return CGSize(width: width*factor, height: height*factor)
    }
}
