//
//  Switch.swift
//  Engine
//
//  Created by Nick Lockwood on 15/08/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

public enum SwitchState {
    case off
    case on
}

public struct Switch {
    public let position: Vector
    public var state: SwitchState = .off
    public var animation: Animation = .switchOff

    public init(position: Vector) {
        self.position = position
    }
}

public extension Switch {
    var rect: Rect {
        return Rect(
            min: position - Vector(x: 0.5, y: 0.5),
            max: position + Vector(x: 0.5, y: 0.5)
        )
    }

    mutating func update(in world: inout World) {
        switch state {
        case .off:
            if world.player.rect.intersection(with: self.rect) != nil {
                state = .on
                animation = .switchFlip
            }
        case .on:
            if animation.isCompleted {
                animation = .switchOn
                world.endLevel()
            }
        }
    }
}

public extension Animation {
    static let switchOff = Animation(frames: [
        .switch1
    ], duration: 0)
    static let switchFlip = Animation(frames: [
        .switch1,
        .switch2,
        .switch3,
        .switch4
    ], duration: 0.4)
    static let switchOn = Animation(frames: [
        .switch4
    ], duration: 0)
}
