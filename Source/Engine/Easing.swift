//
//  Easing.swift
//  Engine
//
//  Created by Nick Lockwood on 23/07/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

public enum Easing {}

public extension Easing {
    static func linear(_ t: Double) -> Double {
        return t
    }

    static func easeIn(_ t: Double) -> Double {
        return t * t
    }

    static func easeOut(_ t: Double) -> Double {
        return 1 - easeIn(1 - t)
    }

    static func easeInEaseOut(_ t: Double) -> Double {
        if t < 0.5 {
            return 2 * easeIn(t)
        } else {
            return 4 * t - 2 * easeIn(t) - 1
        }
    }
}
