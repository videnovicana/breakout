//
//  Constants.swift
//  Breakout
//
//  Created by ana videnovic on 10/20/17.
//  Copyright © 2017 ana videnovic. All rights reserved.
//

import UIKit

struct Constants {
    static let defaultNumberOfBricks: Int = 20
    static let maximumBricks: Int = 50
    static let numberOfBrickColumns: Int = 5
    static let boundsHeightToBrickHeightRatio: CGFloat = 0.03
    static let brickInterspace: CGFloat = 10.0
    static let bricksOffsetFromTop: CGFloat = 50.0
    
    static let brickToPaddleWidthRatio: CGFloat = 1.5
    static let brickToPaddleHeightRatio: CGFloat = 0.5
    static let paddleOffsetFromBottomToHeightRatio: CGFloat = 0.15
    static let boundsHeightToBrickOffsetFromTopRatio: CGFloat = 8
    
    static let brickVanishTime: TimeInterval = 0.5

    static let defaultBallBounciness: CGFloat = 1.0
    static let defautlNumberOfBalls: Int = 1
    static let ballPusherMagnitude: CGFloat = 0.6
    static let ballPusherAngleRange: Range = 4/3*CGFloat.pi..<5/3*CGFloat.pi
    static let defaultGravityMagnitude: CGFloat = 0.1

    static let timeLabelWidthToHeightRatio: CGFloat = 3
    static let timeLableFont = UIFont(name: "CourierNewPS-BoldMT", size: 20)
}

struct BoundaryNames {
    static let brick = "Brick"
    static let paddle = "Paddle"
    static let bounds = "Bounds"
    static let left = "Left"
    static let right = "Right"
    static let upper = "Upper"
}
