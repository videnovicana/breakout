//
//  BallBehavior.swift
//  Breakout
//
//  Created by ana videnovic on 10/20/17.
//  Copyright © 2017 ana videnovic. All rights reserved.
//

import UIKit

class BallBehavior: UIDynamicBehavior, UICollisionBehaviorDelegate {
    
    private var balls = [UIView]()
    
    private let gravity: UIGravityBehavior = {
        let behavior = UIGravityBehavior()
        behavior.magnitude = 0
        return behavior
    } ()
    
    private lazy var collider: UICollisionBehavior = {
        let behavior = UICollisionBehavior()
        behavior.collisionMode = .boundaries
        behavior.collisionDelegate = self
        return behavior
    }()
    
    private var itemBehavior: UIDynamicItemBehavior = {
        let behavior = UIDynamicItemBehavior()
        behavior.allowsRotation = true
        behavior.elasticity = Constants.defaultBallBounciness
        behavior.resistance = 0
        behavior.friction = 0
        behavior.angularResistance = 0
        return behavior
    }()
    
    override init() {
        super.init()
        addChildBehavior(gravity)
        addChildBehavior(collider)
        addChildBehavior(itemBehavior)
        itemBehavior.action = { [weak self] in
            self?.addItemSpeedLimit()
        }
    }
    
    func addItem(_ item: UIDynamicItem) {
        if let ball = item as? UIView {
            balls.append(ball)
        }
        gravity.addItem(item)
        collider.addItem(item)
        itemBehavior.addItem(item)
    }
    
    func removeItem(_ item: UIDynamicItem) {
        if let ball = item as? UIView,
            let index = balls.index(of: ball) {
            balls.remove(at: index)
        }
        gravity.removeItem(item)
        collider.removeItem(item)
        itemBehavior.removeItem(item)
    }
    
    // MARK: - collision boundaries & handlers
    func addBoundary(from point1: CGPoint, to point2: CGPoint, named name: String, collisionHandler: (()->Void)?=nil) {
        collider.removeBoundary(withIdentifier: name as NSString)
        collider.addBoundary(withIdentifier: name as NSString, from: point1, to: point2)
        collisionHandlers[name] = collisionHandler
    }
    
    func addBoundary(_ path: UIBezierPath, named name: String, collisionHandler: (()->Void)?=nil) {
        collider.removeBoundary(withIdentifier: name as NSString)
        collider.addBoundary(withIdentifier: name as NSString, for: path)
        collisionHandlers[name] = collisionHandler
    }
    
    func removeBoundary(named name: String) {
        collider.removeBoundary(withIdentifier: name as NSString)
        collisionHandlers[name] = nil
    }
    
    private var collisionHandlers = [String:()->Void]()
    
    func collisionBehavior(_ behavior: UICollisionBehavior,
        endedContactFor item: UIDynamicItem,
        withBoundaryIdentifier identifier: NSCopying?
    ) {
        if let name = identifier as? String {
            if let handler = collisionHandlers[name] {
                handler()
            }
        }
    }
    
    private var speedLimit: CGFloat = 500.0
    
    private func addItemSpeedLimit() {
        for ball in balls {
            let velocity = itemBehavior.linearVelocity(for: ball)
            let excessHorizontalVelocity = min(speedLimit - velocity.x, 0)
            let excessVerticalVelocity = min(speedLimit - velocity.y, 0)
            itemBehavior.addLinearVelocity(CGPoint(x: excessHorizontalVelocity, y: excessVerticalVelocity), for: ball)
        }
    }
    
    func pushBalls(by magnitude: CGFloat=Constants.ballPusherMagnitude,
                   in direction: CGFloat=CGFloat.random(in: Constants.ballPusherAngleRange)
    ) {
        for ball in balls {
            let pusher = UIPushBehavior(items: [ball], mode: .instantaneous)
            pusher.magnitude = magnitude
            pusher.angle = direction
            pusher.action = { [unowned self] in
                self.removeChildBehavior(pusher)
            }
            addChildBehavior(pusher)
        }
    }
    
    func setGravity(vector: CGVector) {
        gravity.gravityDirection = vector
    }
    
    func setBallBounciness(_ magnitude: CGFloat) {
        itemBehavior.elasticity = magnitude
    }
    
    func setCollidersAction(_ action: @escaping ()->Void) {
        collider.action = action
    }
    
    func clearCollisionBoundariesAndHandlers() {
        collisionHandlers.removeAll()
        collider.removeAllBoundaries()
    }

    func clearItems() {
        for ball in balls {
            removeItem(ball)
        }
    }
}
