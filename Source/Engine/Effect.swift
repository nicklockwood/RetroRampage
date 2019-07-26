//
//  Effect.swift
//  Engine
//
//  Created by Nick Lockwood on 19/07/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

public enum EffectType {
    case fadeIn
    case fadeOut
    case fizzleOut
}

public struct Effect {
    public let type: EffectType
    public let color: Color
    public let duration: Double
    public var time: Double = 0

    public init(type: EffectType, color: Color, duration: Double) {
        self.type = type
        self.color = color
        self.duration = duration
    }
}

public extension Effect {
    var isCompleted: Bool {
        return time >= duration
    }

    var progress: Double {
        let t = min(1, time / duration)
        switch type {
        case .fadeIn:
            return Easing.easeIn(t)
        case .fadeOut:
            return Easing.easeOut(t)
        case .fizzleOut:
            return Easing.easeInEaseOut(t)
        }
    }
}
