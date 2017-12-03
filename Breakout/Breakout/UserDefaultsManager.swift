//
//  UserDefaultsManager.swift
//  Breakout
//
//  Created by ana videnovic on 10/28/17.
//  Copyright © 2017 ana videnovic. All rights reserved.
//

import Foundation

final class UserDefaultsManager {
    
    static let defaults = UserDefaults.standard
    
    struct Keys {
        static let numberOfBricks = "Number Of Bricks"
        static let numberOfBalls = "Number Of Balls"
        static let ballBounciness = "Ball Bounciness"
        static let realGravityIsOn = "Gravity Is On"
    }
    
    static var numberOfBricks: Int? {
        get {
            return defaults.value(forKey: Keys.numberOfBricks) as? Int
        }
        set {
            defaults.set(newValue, forKey: Keys.numberOfBricks)
        }
    }
    
    static var numberOfBalls: Int? {
        get {
            return defaults.value(forKey: Keys.numberOfBalls) as? Int
        }
        set {
            defaults.set(newValue, forKey: Keys.numberOfBalls)
        }
    }
    
    static var ballBounciness: Float? {
        get {
            return defaults.value(forKey: Keys.ballBounciness) as? Float
        }
        set {
            defaults.set(newValue, forKey: Keys.ballBounciness)
        }
    }

    static var realGravityIsOn: Bool? {
        get {
            return defaults.value(forKey: Keys.realGravityIsOn) as? Bool
        }
        set {
            defaults.set(newValue, forKey: Keys.realGravityIsOn)
        }
    }
}
