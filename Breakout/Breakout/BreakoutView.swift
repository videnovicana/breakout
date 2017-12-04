//
//  BreakoutView.swift
//  Breakout
//
//  Created by ana videnovic on 10/20/17.
//  Copyright © 2017 ana videnovic. All rights reserved.
//

import UIKit
import CoreMotion

@IBDesignable
class BreakoutView: UIView {
    
    // MARK: views
    private var bouncingBalls = [(ball: CircleView, isAnimated: Bool)]()
    private var bricks = [UIView?]()
    private var paddle: UIView!

    var ballBehavior: BallBehavior? {
        didSet {
            if ballBehavior != nil {
                ballBehavior!.setCollidersAction { [weak self] in
                    self?.returnBallToPaddleIfNecessary()
                }
                updateRealGravity()
            }
        }
    }
    
    // MARK: - game controlling (settings) variables
    var numberOfBalls: Int = 1 {
        didSet {
            if numberOfBalls != oldValue {
                print("Number of balls: \(numberOfBalls)")
                clearViewToRestartGame()
                setUpNewGameView()
            }
        }
    }
    
    var numberOfBricks: Int = 20 {
        didSet {
            if numberOfBricks != oldValue {
                print("Number of bricks: \(numberOfBricks)")
                clearViewToRestartGame()
                setUpNewGameView()
            }
        }
    }
    
    var ballBounciness: CGFloat = 1.0 {
        didSet {
            print("Elasticity: \(ballBounciness)")
            ballBehavior?.setBallBounciness(ballBounciness)
        }
        
    }
    
    var useRealGravity: Bool = false {
        didSet {
            print("Use real gravity: \(useRealGravity)")
            if ballBehavior != nil {
                updateRealGravity()
            }
        }
    }
    
    private let motionManager = CMMotionManager()
    
    private func updateRealGravity() {
        if useRealGravity {
            if motionManager.isAccelerometerAvailable && !motionManager.isAccelerometerActive {
                motionManager.startAccelerometerUpdates(to: .main) { [unowned self] (data, error) in
                    if self.ballBehavior?.dynamicAnimator != nil {
                        if var dx = data?.acceleration.x, var dy = data?.acceleration.y {
                            switch UIDevice.current.orientation {
                            case .portrait: dy = -dy
                            case .portraitUpsideDown: break
                            case .landscapeLeft: swap(&dx, &dy); dy = -dy
                            case .landscapeRight: swap(&dx, &dy)
                            default: dx = 0; dy=0
                            }
                            self.ballBehavior!.setGravity(vector: CGVector(dx: dx, dy: dy))
                        }
                    } else {
                        self.motionManager.stopAccelerometerUpdates()
                    }
                }
            }
        } else {
            motionManager.stopAccelerometerUpdates()
        }
    }
    
    // MARK: - game lifecycle variable
    private var numberOfBricksDown: Int = 0 {
        didSet {
            if numberOfBricksDown == numberOfBricks {
                clearViewToRestartGame()
                wellDoneNewGameAlert()
            }
        }
    }
    
    private struct WinAlert {
        static let title = "Well Done!"
        static let message = "New game?"
        static let okActionTitle = "OK"
    }
    
    private func wellDoneNewGameAlert() {
        let alert = UIAlertController(title: WinAlert.title, message: WinAlert.message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: WinAlert.okActionTitle, style: .default)
        { [unowned self] action in
            self.setUpNewGameView()
        })
        
        var rootVC = UIApplication.shared.keyWindow?.rootViewController
        if let tabVC = rootVC as? UITabBarController {
            rootVC = tabVC.selectedViewController
        }
        rootVC?.present(alert, animated: true, completion: nil)
    }
    
    func setUpNewGameView() {
        if ballBehavior != nil { // unless we have a behavior it's pointless to set up anything
            addScreenBoundaryToBehavior()
            drawBricksAndAddTheirBoundariesToBehavior()
            drawPaddleAndAddItsBoundaryToBehavior()
            drawBalls()
        }
    }
    
    private func clearViewToRestartGame() {
        ballBehavior?.clearCollisionBoundariesAndHandlers()
        deleteBalls()
        deleteBricks()
        deletePaddle()
    }
    
    func redrawGameViewUponRotation() {
        if ballBehavior != nil {
            ballBehavior!.clearCollisionBoundariesAndHandlers()
            withdrawBricksFromGameView()
            deletePaddle()
            
            addScreenBoundaryToBehavior()
            redrawExistingBricksAndTheirBoundaries()
            drawPaddleAndAddItsBoundaryToBehavior()
            resizeAndMoveBallsUponRotation()
        }
    }
    
    private func resizeAndMoveBallsUponRotation() {
        for (ball, isAnimated) in bouncingBalls {
            ball.frame.size = ballSize
            if !isAnimated {
                ball.center = newBallCenter
            }
            ball.layoutIfNeeded()
        }
    }
    
    private func addScreenBoundaryToBehavior() {
        assert(ballBehavior != nil, "Unexpected case: addScreenBoundaryToBehavior can only be called when ballBehavior is already set.")
        let gameRectangle = bounds.insetBy(dx: Constants.brickInterspace, dy:  Constants.brickInterspace)
        ballBehavior!.addBoundary(from: gameRectangle.lowerLeft, to: gameRectangle.upperLeft, named: BoundaryNames.left)
        ballBehavior!.addBoundary(from: gameRectangle.upperLeft, to: gameRectangle.upperRight, named: BoundaryNames.upper)
        ballBehavior!.addBoundary(from: gameRectangle.lowerRight, to: gameRectangle.upperRight, named: BoundaryNames.right)
    }
    
    private func drawBricksAndAddTheirBoundariesToBehavior() {
        var numberOfDrawnBricks = 0
        var upperLeftPointOfNextBrick = CGPoint(x: Constants.brickInterspace, y: Constants.bricksOffsetFromTop)
        
        while numberOfDrawnBricks < numberOfBricks {
            
            if (numberOfDrawnBricks != 0) && (numberOfDrawnBricks % Constants.numberOfBrickColumns == 0) { // new line
                upperLeftPointOfNextBrick.x = Constants.brickInterspace
                upperLeftPointOfNextBrick.y += brickSize.height + Constants.brickInterspace
            }
            
            let brick = UIView(frame: CGRect(origin: upperLeftPointOfNextBrick, size: brickSize))
            brick.backgroundColor = Colors.brick
            bricks.append(brick)
            addSubview(brick)
            
            let brickBoundaryPath = UIBezierPath(rect: brick.frame)
            let brickBoundaryName = BoundaryNames.brick + String(numberOfDrawnBricks)
            ballBehavior!.addBoundary(brickBoundaryPath,
                                      named: brickBoundaryName,
                                      collisionHandler: { [weak self] in
                                        UIView.animate(
                                            withDuration: Constants.brickVanishTime,
                                            delay: 0.0,
                                            options: [.curveEaseOut],
                                            animations: {
                                                brick.backgroundColor = Colors.hitBrick
                                                self?.ballBehavior?.removeBoundary(named: brickBoundaryName)
                                                Timer.scheduledTimer(withTimeInterval: Constants.brickVanishTime, repeats: false) { timer in
                                                    brick.alpha = 0.0
                                                }
                                            },
                                            completion: { finished in
                                                if finished {
                                                    brick.removeFromSuperview()
                                                    let indexOfInt = brickBoundaryName.index(brickBoundaryName.startIndex, offsetBy: 5)
                                                    //TODO: extracting int from string is probably a temporary solution.
                                                    // 5 is number of chars in "Brick12" before int appears. This should be done more thoughtfully.
                                                    if let index = Int(brickBoundaryName[indexOfInt...]) {
                                                        self?.bricks[index] = nil
                                                    }
                                                    self?.numberOfBricksDown += 1
                                                }
                                            }
                                        )
                }
            )
            upperLeftPointOfNextBrick.x += brickSize.width + Constants.brickInterspace
            numberOfDrawnBricks += 1
        }
    }
    
    private func redrawExistingBricksAndTheirBoundaries() {
        var numberOfDrawnBricks = 0
        var upperLeftPointOfNextBrick = CGPoint(x: Constants.brickInterspace, y: Constants.bricksOffsetFromTop)

        for (index, brick) in bricks.enumerated() {
            
            if (numberOfDrawnBricks != 0) && (numberOfDrawnBricks % Constants.numberOfBrickColumns == 0) { // new line
                upperLeftPointOfNextBrick.x = Constants.brickInterspace
                upperLeftPointOfNextBrick.y += brickSize.height + Constants.brickInterspace
            }
            
            if brick != nil {
                bricks[index] = nil
                let newBrick = UIView(frame: CGRect(origin: upperLeftPointOfNextBrick, size: brickSize))
                newBrick.backgroundColor = Colors.brick
                bricks[index] = newBrick
                addSubview(newBrick)
                
                let brickBoundaryPath = UIBezierPath(rect: newBrick.frame)
                let brickBoundaryName = BoundaryNames.brick + String(numberOfDrawnBricks)  // Starts with Brick0
                ballBehavior!.addBoundary(brickBoundaryPath,
                              named: brickBoundaryName,
                              collisionHandler: { [weak self] in
                                UIView.animate(
                                    withDuration: Constants.brickVanishTime,
                                    delay: 0.0,
                                    options: [.curveEaseOut],
                                    animations: {
                                        newBrick.backgroundColor = Colors.hitBrick
                                        self?.ballBehavior?.removeBoundary(named: brickBoundaryName)
                                        Timer.scheduledTimer(withTimeInterval: Constants.brickVanishTime, repeats: false) { timer in
                                            newBrick.alpha = 0.0
                                        }
                                    },
                                    completion: { finished in
                                        if finished {
                                            newBrick.removeFromSuperview()
                                            let boundarySerialNumberStartIndex = brickBoundaryName.index(
                                                brickBoundaryName.startIndex,
                                                offsetBy: BoundaryNames.brick.count
                                            )
                                            if let index = Int(brickBoundaryName[boundarySerialNumberStartIndex...]) {
                                                self?.bricks[index] = nil
                                            }
                                            self?.numberOfBricksDown += 1
                                        }
                                    }
                                )
                    }
                )
            }
            upperLeftPointOfNextBrick.x += brickSize.width + Constants.brickInterspace
            numberOfDrawnBricks += 1
        }
    }
    
    private func drawPaddleAndAddItsBoundaryToBehavior() {
        deletePaddle()
        paddle = UIView(frame: CGRect(center: initialPaddleCenter, size: paddleSize))
        paddle.backgroundColor = Colors.paddle
        addSubview(paddle)
        assert(ballBehavior != nil, "Unexpected case: drawPaddleAndAddItsBoundaryToBehavior can only be called when ballBehavior is already set.")
        let paddleBoundaryPath = UIBezierPath(ovalIn: paddle.frame)
        ballBehavior!.addBoundary(paddleBoundaryPath, named: BoundaryNames.paddle)
    }
    
    private func drawBalls() {
        var numberOfBallsAdded = bouncingBalls.count
        while numberOfBallsAdded < numberOfBalls {
            addBall()
            numberOfBallsAdded += 1
        }
    }
    
    func addBall() {
        let ball = CircleView(frame: CGRect(center: newBallCenter, size: ballSize))
        bouncingBalls.append((ball, false))
        ball.backgroundColor = Colors.ball
        addSubview(ball)
    }
    
    func removeBall() {
        let (ball, isAnimated) = bouncingBalls.removeLast()
        ball.removeFromSuperview()
        if isAnimated {
            ballBehavior?.removeItem(ball)
        }
    }
    
    private func deleteBalls() {
        for (ball, _) in bouncingBalls {
            ballBehavior?.removeItem(ball)
            ball.removeFromSuperview()
        }
        bouncingBalls.removeAll()
    }
    
    private func deleteBricks() {
        withdrawBricksFromGameView()
        bricks.removeAll()
        numberOfBricksDown = 0
    }
    
    private func deletePaddle() {
        if paddle != nil {
            //ballBehavior?.removeBoundary(named: BoundaryNames.paddle)
            paddle.removeFromSuperview()
            paddle = nil
        }
    }
    
    private func withdrawBricksFromGameView() {
        for brick in bricks {
            brick?.removeFromSuperview()
            //ballBehavior?.removeBoundary(named: BoundaryNames.brick + String(index))
        }
    }
    
    private var brickSize: CGSize {
        return CGSize(
            width: (bounds.width - Constants.brickInterspace * CGFloat(Constants.numberOfBrickColumns+1)) / 5,
            height: bounds.height * Constants.boundsHeightToBrickHeightRatio
        )
    }
    
    private var paddleSize: CGSize {
        return CGSize(
            width: brickSize.width * Constants.brickToPaddleWidthRatio,
            height: brickSize.height * Constants.brickToPaddleHeightRatio
        )
    }
    
    private var ballSize: CGSize {
        return CGSize(width: brickSize.height, height: brickSize.height)
    }
    
    private var initialPaddleCenter: CGPoint {
        return CGPoint(x: bounds.midX, y: bounds.maxY - paddleOffsetFromBottom)
    }
    
    private var paddleOffsetFromBottom: CGFloat {
        return bounds.height * Constants.paddleOffsetFromBottomToHeightRatio
    }
    
    private var paddleCenterXValueRange: Range<CGFloat> {
        return (paddleSize.width/2)..<(bounds.width - paddleSize.width/2)
    }
    
    private var maximumAllowedPaddleTranslationAlongXAxisToTheLeft: CGFloat {
        return paddleCenterXValueRange.lowerBound - paddle.center.x
    }
    
    private var maximumAllowedPaddleTranslationAlongXAxisToTheRight: CGFloat {
        return paddleCenterXValueRange.upperBound - paddle.center.x
    }
    
    private var newBallCenter: CGPoint {
        return CGPoint(
            x: paddle?.center.x ?? bounds.midX,
            y: initialPaddleCenter.y - paddleSize.height/2 - ballSize.height/2
        )
    }
    
    private struct Colors {
        static let brick = UIColor.blue
        static let hitBrick = UIColor.purple
        static let ball = UIColor.red
        static let paddle = UIColor.green
    }
    
    // MARK: handling gestures
    @objc func pushBalls(byReactingTo recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended {
            addBallsToAnimatorIfNotAlreadySo()
            ballBehavior?.pushBalls()
        }
    }
    
    @objc func movePaddle(byReactingTo recognizer: UIPanGestureRecognizer) {
        if paddle != nil {
            switch recognizer.state {
            case .began, .changed:
                let translationAlongXAxis = recognizer.translation(in: self).x
                recognizer.setTranslation(CGPoint.zero, in: self)
                paddle.center.x += translationAlongXAxis < 0 ?
                    max(translationAlongXAxis, maximumAllowedPaddleTranslationAlongXAxisToTheLeft) :
                    min(translationAlongXAxis, maximumAllowedPaddleTranslationAlongXAxisToTheRight)
                moveBallsWaitingOnPaddle()
                ballBehavior?.addBoundary(UIBezierPath(ovalIn: paddle.frame), named: BoundaryNames.paddle)
            default:
                break
            }
        }
    }
    
    private func addBallsToAnimatorIfNotAlreadySo() {
        if ballBehavior != nil {
            for (offset: index, element: (ball: ball, isAnimated: isAnimated)) in bouncingBalls.enumerated() {
                if !isAnimated {
                    ballBehavior!.addItem(ball)
                    bouncingBalls[index].isAnimated = true
                }
            }
        }
    }
    
    private func moveBallsWaitingOnPaddle() {
        for (ball, isAnimated) in bouncingBalls {
            if !isAnimated {
                ball.center = newBallCenter
            }
        }
    }
    
    private func returnBallToPaddleIfNecessary() {
        if let animator = ballBehavior?.dynamicAnimator {
            for (offset: index, element: (ball: ball, isAnimated: _)) in bouncingBalls.enumerated() {
                if let gameBounds = animator.referenceView?.bounds.insetBy(dx: ball.frame.size.width/2, dy: ball.frame.size.height/2),
                    !gameBounds.contains(ball.center) {
                    
                    ballBehavior!.removeItem(ball)
                    bouncingBalls[index].isAnimated = false
                    ball.transform = CGAffineTransform.identity
                    ball.center = newBallCenter
                }
            }
        }
    }
}
