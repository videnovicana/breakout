//
//  BreakoutViewController.swift
//  Breakout
//
//  Created by ana videnovic on 10/20/17.
//  Copyright © 2017 ana videnovic. All rights reserved.
//

import UIKit

class BreakoutViewController: UIViewController {
    
    // MARK: - view
    private var gameView: BreakoutView! {
        didSet {
            gameView.addGestureRecognizer(UITapGestureRecognizer(target: gameView, action: #selector(BreakoutView.pushBalls(byReactingTo:))))
            gameView.addGestureRecognizer(UIPanGestureRecognizer(target: gameView, action: #selector(BreakoutView.movePaddle(byReactingTo:))))
        }
    }
    
    // MARK: - view animating tools
    private lazy var animator: UIDynamicAnimator = UIDynamicAnimator(referenceView: self.gameView)
    private var ballBehavior = BallBehavior()
    
    // MARK: - view life cycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        initializeIfNeeded()
        animator.addBehavior(ballBehavior)
        refreshSettings()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        animator.removeBehavior(ballBehavior)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if gameView != nil {
            gameView.frame = self.view.bounds
            gameView.redrawGameViewUponRotation()
        }
    }
    
    private func initializeIfNeeded() {
        if gameView == nil {
            gameView = BreakoutView(frame: CGRect(center: view.bounds.mid, size: view.bounds.size))
            view.addSubview(gameView)
            gameView.ballBehavior = ballBehavior
            gameView.useRealGravity = UserDefaultsManager.realGravityIsOn ?? false
            gameView.setUpNewGameView()
        }
    }

    private func refreshSettings() {
        gameView.numberOfBalls = UserDefaultsManager.numberOfBalls ?? Constants.defautlNumberOfBalls
        gameView.numberOfBricks = UserDefaultsManager.numberOfBricks ?? Constants.defaultNumberOfBricks
        gameView.useRealGravity = UserDefaultsManager.realGravityIsOn ?? false
        if let bounciness = UserDefaultsManager.ballBounciness {
            gameView.ballBounciness = CGFloat(bounciness)
        }
    }
}
