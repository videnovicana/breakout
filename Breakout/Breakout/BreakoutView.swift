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
    private var bricks = [SpotlightView?]()
    private var rays = [RayLayer?]()
    private var limelight: LimelightView?
    private var paddle: UIView!
    private var timeLabel = UILabel()

    var ballBehavior: BallBehavior? {
        didSet {
            if let behavior = ballBehavior {
                behavior.setCollidersAction { [weak self] in
                    self?.returnBallToPaddleIfNecessary()
                }
                updateRealGravity(in: behavior)
            }
        }
    }
    
    // MARK: - game controlling (settings) variables
    var numberOfBalls: Int = 1 {
        didSet {
            if numberOfBalls != oldValue {
                clearViewToRestartGame()
                setUpNewGameView()
            }
        }
    }
    
    var numberOfBricks: Int = 20 {
        didSet {
            if numberOfBricks != oldValue {
                clearViewToRestartGame()
                setUpNewGameView()
            }
        }
    }
    
    var ballBounciness: CGFloat = 1.0 {
        didSet {
            ballBehavior?.setBallBounciness(ballBounciness)
        }
    }
    
    var useRealGravity: Bool = false {
        didSet {
            if let behavior = ballBehavior {
                updateRealGravity(in: behavior)
            }
        }
    }
    
    private let motionManager = CMMotionManager()
    
    private func updateRealGravity(in behavior: BallBehavior) {
        if useRealGravity {
            if motionManager.isAccelerometerAvailable && !motionManager.isAccelerometerActive {
                motionManager.startAccelerometerUpdates(to: .main) { [unowned self] (data, error) in
                    if behavior.dynamicAnimator != nil {
                        if var dx = data?.acceleration.x, var dy = data?.acceleration.y {
                            switch UIDevice.current.orientation {
                            case .portrait: dy = -dy
                            case .portraitUpsideDown: break
                            case .landscapeLeft: swap(&dx, &dy); dy = -dy
                            case .landscapeRight: swap(&dx, &dy)
                            default: dx = 0; dy=0
                            }
                            behavior.setGravity(vector: CGVector(dx: dx, dy: dy))
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

    // MARK: - Measuring time
    private var timeCounter = 0
    private var timer: Timer?

    private func startTimerIfNeeded() {
        if timer == nil {
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        }
    }

    @objc private func updateTimer() {
        timeCounter += 1
        timeLabel.text = "Time: \(timeCounter)"
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func resetCounter() {
        timeCounter = 0
    }

    // MARK: - game lifecycle variable
    private var numberOfBricksDown: Int = 0 {
        didSet {
            if numberOfBricksDown == numberOfBricks {
                stopTimer()
                clearViewToRestartGame()
                if let delegate = highScoresDelegate, delegate.checkIfNewHigh(score: timeCounter, forBallCount: numberOfBalls) {
                    delegate.updateHighScores(with: timeCounter, forBallCount: numberOfBalls)
                } else {
                    wellDoneNewGameAlert()
                }
           }
        }
    }

    weak var highScoresDelegate: HighScoresDelegate?

    private func wellDoneNewGameAlert() {
        let alert = UIAlertController(title: "Well Done!", message: scoreInformationMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default)
        { [unowned self] action in
            self.setUpNewGameView()
        })
        
        var rootVC = UIApplication.shared.keyWindow?.rootViewController
        if let tabVC = rootVC as? UITabBarController {
            rootVC = tabVC.selectedViewController
        }
        rootVC?.present(alert, animated: true, completion: nil)
    }

    private var scoreInformationMessage: String {
        return "Time: \(timeCounter)"
    }
    
    func setUpNewGameView() {
        if let behavior = ballBehavior {
            addScreenBoundary(to: behavior)
            drawPaddleAndAddItsBoundary(to: behavior)
            drawBricksAndAddTheirBoundaries(to: behavior)
            drawBalls()
            resetCounter()
            addTimeLabel()
            addLimelight()
        }
    }
    
    private func clearViewToRestartGame() {
        ballBehavior?.clearCollisionBoundariesAndHandlers()
        deleteBalls()
        deleteBricks()
        deletePaddle()
        deleteTimeLabel()
        deleteLimelight()
    }
    
    func redrawGameViewUponRotation() {
        if let behavior = ballBehavior {
            behavior.clearCollisionBoundariesAndHandlers()
            withdrawBricksFromGameView()
            deletePaddle()

            addScreenBoundary(to: behavior)
            drawPaddleAndAddItsBoundary(to: behavior)
            redrawExistingBricksAndAddTheirBoundaries(to: behavior)
            resizeAndMoveBallsUponRotation()
            redrawTimeLabel()
            redrawLimeLight()
        }
    }
    
    private func resizeAndMoveBallsUponRotation() {
        for (ball, isAnimated) in bouncingBalls {
            ball.frame.size = ballSize
            bringSubview(toFront: ball)
            if !isAnimated {
                ball.center = newBallCenter
            }
            ball.layoutIfNeeded()
        }
    }
    
    private func addScreenBoundary(to behavior: BallBehavior) {
        let gameRectangle = bounds.insetBy(dx: Constants.brickInterspace, dy:  Constants.brickInterspace)
        behavior.addBoundary(from: gameRectangle.lowerLeft, to: gameRectangle.upperLeft, named: BoundaryNames.left)
        behavior.addBoundary(from: gameRectangle.upperLeft, to: gameRectangle.upperRight, named: BoundaryNames.upper)
        behavior.addBoundary(from: gameRectangle.lowerRight, to: gameRectangle.upperRight, named: BoundaryNames.right)
    }

    private func drawBricksAndAddTheirBoundaries(to behavior: BallBehavior) {
        var numberOfDrawnBricks = 0
        var upperLeftPointOfNextBrick = CGPoint(x: Constants.brickInterspace, y: bricksOffsetFromTop)
        
        while numberOfDrawnBricks < numberOfBricks {
            
            if (numberOfDrawnBricks != 0) && (numberOfDrawnBricks % Constants.numberOfBrickColumns == 0) { // new line
                upperLeftPointOfNextBrick.x = Constants.brickInterspace
                upperLeftPointOfNextBrick.y += brickSize.height + Constants.brickInterspace
            }
            
            let brick = SpotlightView(
                ellipseIn: CGRect(origin: upperLeftPointOfNextBrick, size: brickSize),
                following: paddle.center
            )
            bricks.append(brick)

            let ray = RayLayer(in: bounds, comingFrom: brick, to: limelightRect)
            rays.append(ray)

            layer.addSublayer(ray)
            addSubview(brick)

            let brickBoundaryPath = UIBezierPath(rect: brick.frame)
            let brickBoundaryName = BoundaryNames.brick + String(numberOfDrawnBricks)
            behavior.addBoundary(
                brickBoundaryPath,
                named: brickBoundaryName,
                collisionHandler: { [weak self] in
                    UIView.animate(
                        withDuration: Constants.brickVanishTime,
                        delay: 0.0,
                        options: [.curveEaseOut],
                        animations: {
                            //TODO: make some hitBrick Animation
                            behavior.removeBoundary(named: brickBoundaryName)
                            Timer.scheduledTimer(withTimeInterval: Constants.brickVanishTime, repeats: false) { timer in
                                brick.alpha = 0.0
                            }
                        },
                        completion: { finished in
                            if finished {
                                ray.removeFromSuperlayer()
                                brick.removeFromSuperview()
                                let indexOfInt = brickBoundaryName.index(brickBoundaryName.startIndex, offsetBy: 5)
                                //TODO: extracting int from string is probably a temporary solution.
                                // 5 is number of chars in "Brick12" before int appears. This should be done more thoughtfully.
                                if let index = Int(brickBoundaryName[indexOfInt...]) {
                                    self?.bricks[index] = nil
                                    self?.rays[index] = nil
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

    private func redrawExistingBricksAndAddTheirBoundaries(to behavior: BallBehavior) {
        var numberOfDrawnBricks = 0
        var upperLeftPointOfNextBrick = CGPoint(x: Constants.brickInterspace, y: bricksOffsetFromTop)

        for (index, brick) in bricks.enumerated() {
            
            if (numberOfDrawnBricks != 0) && (numberOfDrawnBricks % Constants.numberOfBrickColumns == 0) { // new line
                upperLeftPointOfNextBrick.x = Constants.brickInterspace
                upperLeftPointOfNextBrick.y += brickSize.height + Constants.brickInterspace
            }
            
            if brick != nil {
                bricks[index] = nil
                let newBrick = SpotlightView(
                    ellipseIn: CGRect(origin: upperLeftPointOfNextBrick, size: brickSize),
                    following: paddle.center
                )

                bricks[index] = newBrick

                rays[index] = nil
                let ray = RayLayer(in: bounds, comingFrom: newBrick, to: limelightRect)
                rays[index] = ray

                layer.addSublayer(ray)
                addSubview(newBrick)

                let brickBoundaryPath = UIBezierPath(rect: newBrick.frame)
                let brickBoundaryName = BoundaryNames.brick + String(numberOfDrawnBricks)  // Starts with Brick0
                behavior.addBoundary(
                    brickBoundaryPath,
                    named: brickBoundaryName,
                    collisionHandler: { [weak self] in
                        UIView.animate(
                            withDuration: Constants.brickVanishTime,
                            delay: 0.0,
                            options: [.curveEaseOut],
                            animations: {
                                //TODO: make some hitBrick Animation
                                behavior.removeBoundary(named: brickBoundaryName)
                                Timer.scheduledTimer(withTimeInterval: Constants.brickVanishTime, repeats: false) { timer in
                                    newBrick.alpha = 0.0
                                }
                            },
                            completion: { finished in
                                if finished {
                                    ray.removeFromSuperlayer()
                                    newBrick.removeFromSuperview()
                                    let boundarySerialNumberStartIndex = brickBoundaryName.index(
                                        brickBoundaryName.startIndex,
                                        offsetBy: BoundaryNames.brick.count
                                    )
                                    if let index = Int(brickBoundaryName[boundarySerialNumberStartIndex...]) {
                                        self?.bricks[index] = nil
                                        self?.rays[index] = nil
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

    private func drawPaddleAndAddItsBoundary(to behavior: BallBehavior) {
        deletePaddle()
        paddle = UIView(frame: CGRect(center: initialPaddleCenter, size: paddleSize))
        paddle.backgroundColor = Colors.paddle
        addSubview(paddle)
        let paddleBoundaryPath = UIBezierPath(ovalIn: paddle.frame)
        behavior.addBoundary(paddleBoundaryPath, named: BoundaryNames.paddle)
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
        rays.removeAll()
    }
    
    private func deletePaddle() {
        paddle?.removeFromSuperview()
        paddle = nil
    }
    
    private func withdrawBricksFromGameView() {
        for brick in bricks {
            brick?.removeFromSuperview()
        }
        withdrawRaysFromGameView()
    }

    private func withdrawRaysFromGameView() {
        for ray in rays {
            ray?.removeFromSuperlayer()
        }
    }

    private func addLimelight() {
        limelight = LimelightView(ellipseIn: limelightRect)
        if let limelight = limelight {
            addSubview(limelight)
        }
    }

    private func redrawLimeLight() {
        limelight?.setEllipseShape(in: limelightRect)
    }

    private func deleteLimelight() {
        limelight?.removeFromSuperview()
        limelight = nil
    }

    private func addTimeLabel() {
        timeLabel.frame = timeLabelRect
        timeLabel.text = "Time: \(timeCounter)"
        timeLabel.font = Constants.timeLableFont
        timeLabel.textColor = UIColor.gray
        addSubview(timeLabel)
    }

    private func redrawTimeLabel() {
        timeLabel.frame = timeLabelRect
    }

    private func deleteTimeLabel() {
        timeLabel.removeFromSuperview()
    }

    private var timeLabelRect: CGRect {
        return CGRect(
            origin: CGPoint(x: Constants.brickInterspace, y: Constants.brickInterspace),
            size: CGSize(width: bricksOffsetFromTop * Constants.timeLabelWidthToHeightRatio, height: bricksOffsetFromTop)
        )
    }

    private var brickSize: CGSize {
        return CGSize(
            width: (bounds.width - Constants.brickInterspace * CGFloat(Constants.numberOfBrickColumns+1)) / CGFloat(Constants.numberOfBrickColumns),
            height: bounds.height * Constants.boundsHeightToBrickHeightRatio
        )
    }

    private var bricksOffsetFromTop: CGFloat {
        return max(Constants.bricksOffsetFromTop, bounds.height/Constants.boundsHeightToBrickOffsetFromTopRatio)
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

    private var limelightRect: CGRect {
        return CGRect(
            center: CGPoint(x: paddle.center.x, y: paddle.center.y + paddle.frame.height/2),
            size: paddle.frame.size.scaled(by: Constants.limelightToPaddleSizeRatio))
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

    // MARK: handling gestures
    @objc func pushBalls(byReactingTo recognizer: UITapGestureRecognizer) {
        if recognizer.state == .ended, let behavior = ballBehavior {
            addBallsToAnimatorIfNotAlreadySo(using: behavior)
            behavior.pushBalls()
            startTimerIfNeeded()
        }
    }
    
    @objc func movePaddle(byReactingTo recognizer: UIPanGestureRecognizer) {
        if paddle != nil {
            switch recognizer.state {
            case .began, .changed:
                let translationAlongXAxis = recognizer.translation(in: self).x
                recognizer.setTranslation(CGPoint.zero, in: self)

                let dx = translationAlongXAxis < 0 ?
                    max(translationAlongXAxis, maximumAllowedPaddleTranslationAlongXAxisToTheLeft) :
                    min(translationAlongXAxis, maximumAllowedPaddleTranslationAlongXAxisToTheRight)

                paddle.center.x += dx

                moveBallsWaitingOnPaddle()
                ballBehavior?.addBoundary(UIBezierPath(ovalIn: paddle.frame), named: BoundaryNames.paddle)

                animateSpotlightChasing(paddleMovedBy: dx)
            default:
                break
            }
        }
    }
    
    private func addBallsToAnimatorIfNotAlreadySo(using behavior: BallBehavior) {
        for (offset: index, element: (ball: ball, isAnimated: isAnimated)) in bouncingBalls.enumerated() {
            if !isAnimated {
                behavior.addItem(ball)
                bouncingBalls[index].isAnimated = true
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

    private func animateSpotlightChasing(paddleMovedBy dx: CGFloat) {
        CATransaction.begin()
        CATransaction.setAnimationDuration(Constants.spotlightTurnTime)
        CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear))

        turnBricksAndRaysToFollowPaddle()
        limelight?.moveCenterAlongXAxisBy(dx: dx)

        CATransaction.commit()
    }

    private func turnBricksAndRaysToFollowPaddle() {
        for (index, brick) in bricks.enumerated() {
            if let brick = brick {
                brick.follow(point: paddle.center)
                rays[index]?.setShape(from: brick, to: limelightRect)
            }
        }
    }

    private func returnBallToPaddleIfNecessary() {
        if let behavior = ballBehavior, let animator = behavior.dynamicAnimator {
            for (offset: index, element: (ball: ball, isAnimated: _)) in bouncingBalls.enumerated() {
                if let gameBounds = animator.referenceView?.bounds.insetBy(dx: ball.frame.size.width/2, dy: ball.frame.size.height/2),
                    !gameBounds.contains(ball.center) {
                    
                    behavior.removeItem(ball)
                    bouncingBalls[index].isAnimated = false
                    ball.transform = CGAffineTransform.identity
                    ball.center = newBallCenter
                }
            }
        }
    }
}
