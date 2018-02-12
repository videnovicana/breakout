//
//  RayLayer.swift
//  Breakout
//
//  Created by ana videnovic on 2/7/18.
//  Copyright © 2018 ana videnovic. All rights reserved.
//

import UIKit

class RayLayer: CAGradientLayer {

    convenience init(in rect: CGRect, comingFrom brick: SpotlightView, to limelightRect: CGRect) {
        self.init()

        self.frame = rect
        self.colors = [Colors.rayColor.cgColor, UIColor.clear.cgColor]
        self.locations = [0, 0.6]
        self.opacity = 1

        initialShape(using: initialVertices(from: brick, limelightRect: limelightRect))
        reShape(using: verticesForRayComing(from: brick, limelightRect: limelightRect))
    }

    func setShape(from brick: SpotlightView, to limelightRect: CGRect) {
        reShape(using: verticesForRayComing(from: brick, limelightRect: limelightRect))
    }

    private var shapeLayer: CAShapeLayer?

    private func initialShape(using vertices: [CGPoint]) {

        guard let path = closedPath(from: vertices) else {
            return
        }

        shapeLayer = CAShapeLayer()
        shapeLayer?.path = path.cgPath
        self.mask = shapeLayer
    }

    private func reShape(using vertices: [CGPoint]) {

        guard let path = closedPath(from: vertices) else {
            return
        }

        if shapeLayer == nil {
            shapeLayer = CAShapeLayer()
            self.mask = shapeLayer
        }

        newPath = path.cgPath

        let presentationLayer = shapeLayer?.presentation()
        let currentPath = presentationLayer?.path

        let animation = CABasicAnimation(keyPath: "path")
        animation.delegate = self

        animation.fromValue = currentPath
        animation.toValue = newPath
        animation.duration = Constants.spotlightTurnTime

        shapeLayer?.add(animation, forKey: animation.keyPath)
    }

    private func initialVertices(from brick: SpotlightView, limelightRect: CGRect) -> [CGPoint] {

        let brickHalfWidth = brick.bounds.width/2

        var upperLeftRayVertex = brick.center
        upperLeftRayVertex.x -= brickHalfWidth
        var upperRightRayVertex = brick.center
        upperRightRayVertex.x += brickHalfWidth

        let offset = (brick.layer.position.x - self.position.x)

        var lowerRightRayVertex = limelightRect.midRight
        lowerRightRayVertex.x += offset
        var lowerLeftRayVertex = limelightRect.midLeft
        lowerLeftRayVertex.x += offset

        return [upperLeftRayVertex, upperRightRayVertex, lowerRightRayVertex, lowerLeftRayVertex]
    }

    private func verticesForRayComing(from brick: SpotlightView, limelightRect: CGRect) -> [CGPoint] {

        let brickHalfWidth = brick.bounds.width/2

        var upperLeftRayVertex = brick.center
        upperLeftRayVertex.x -= brickHalfWidth
        upperLeftRayVertex = upperLeftRayVertex.rotated(by: brick.newRotationAngle ?? 0, around: brick.center)

        var upperRightRayVertex = brick.center
        upperRightRayVertex.x += brickHalfWidth
        upperRightRayVertex = upperRightRayVertex.rotated(by: brick.newRotationAngle ?? 0, around: brick.center)

        let lowerRightRayVertex = limelightRect.midRight
        let lowerLeftRayVertex = limelightRect.midLeft

        return [upperLeftRayVertex, upperRightRayVertex, lowerRightRayVertex, lowerLeftRayVertex]
    }

    private func closedPath(from vertices: [CGPoint]) -> UIBezierPath? {

        guard vertices.count == 4 else {
            return nil
        }

        let path = UIBezierPath()
        path.move(to: vertices[0])
        path.addLine(to: vertices[1])
        path.addLine(to: vertices[2])
        path.addLine(to: vertices[3])
        path.close()

        return path
    }

    private var newPath: CGPath?
}

extension RayLayer: CAAnimationDelegate {

    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {

        if flag, let basicAnimation = anim as? CABasicAnimation,
            basicAnimation.keyPath == "path",
            let newPath = newPath {
            shapeLayer?.path = newPath
        }
    }
}
