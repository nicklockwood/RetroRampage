//
//  Door.swift
//  Engine
//
//  Created by Nick Lockwood on 10/08/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

public enum DoorState {
    case closed
    case opening
    case open
    case closing
}

public struct Door {
    public let duration: Double = 0.5
    public let closeDelay: Double = 3
    public let position: Vector
    public let direction: Vector
    public let texture: Texture
    public var state: DoorState = .closed
    public var time: Double = 0

    public init(position: Vector, isVertical: Bool) {
        self.position = position
        if isVertical {
            self.direction = Vector(x: 0, y: 1)
            self.texture = .door
        } else {
            self.direction = Vector(x: 1, y: 0)
            self.texture = .door2
        }
    }
}

public extension Door {
    var rect: Rect {
        let position = self.position + direction * (offset - 0.5)
        let depth = direction.orthogonal * 0.1
        return Rect(min: position + depth, max: position + direction - depth)
    }

    var offset: Double {
        let t = min(1, time / duration)
        switch state {
        case .closed:
            return 0
        case .opening:
            return Easing.easeInEaseOut(t)
        case .open:
            return 1
        case .closing:
            return 1 - Easing.easeInEaseOut(t)
        }
    }

    var billboard: Billboard {
        return Billboard(
            start: position + direction * (offset - 0.5),
            direction: direction,
            length: 1,
            texture: texture
        )
    }

    func hitTest(_ ray: Ray) -> Vector? {
        return billboard.hitTest(ray)
    }

    mutating func update(in world: inout World) {
        switch state {
        case .closed:
            if world.player.intersection(with: self) != nil ||
                world.monsters.contains(where: { monster in
                    monster.isDead == false &&
                        monster.intersection(with: self) != nil
                }) {
                state = .opening
                world.playSound(.doorSlide, at: position)
                time = 0
            }
        case .opening:
            if time >= duration {
                state = .open
                time = 0
            }
        case .open:
            if time >= closeDelay {
                state = .closing
                world.playSound(.doorSlide, at: position)
                time = 0
            }
        case .closing:
            if time >= duration {
                state = .closed
                time = 0
            }
        }
    }
}
