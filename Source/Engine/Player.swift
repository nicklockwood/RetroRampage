//
//  Player.swift
//  Engine
//
//  Created by Nick Lockwood on 02/06/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

public enum PlayerState {
    case idle
    case firing
}

public struct Player: Actor {
    public let speed: Double = 2
    public let turningSpeed: Double = .pi
    public let radius: Double = 0.25
    public var position: Vector
    public var velocity: Vector
    public var direction: Vector
    public var health: Double
    public var state: PlayerState = .idle
    public var animation: Animation = .pistolIdle
    public let attackCooldown: Double = 0.25

    public init(position: Vector) {
        self.position = position
        self.velocity = Vector(x: 0, y: 0)
        self.direction = Vector(x: 1, y: 0)
        self.health = 100
    }
}

public extension Player {
    var isDead: Bool {
        return health <= 0
    }

    var canFire: Bool {
        switch state {
        case .idle:
            return true
        case .firing:
            return animation.time >= attackCooldown
        }
    }

    mutating func update(with input: Input, in world: inout World) {
        direction = direction.rotated(by: input.rotation)
        velocity = direction * input.speed * speed
        if input.isFiring, canFire {
            state = .firing
            animation = .pistolFire
            let ray = Ray(origin: position, direction: direction)
            if let index = world.pickMonster(ray) {
                world.hurtMonster(at: index, damage: 10)
            }
        }
        switch state {
        case .idle:
            break
        case .firing:
            if animation.isCompleted {
                state = .idle
                animation = .pistolIdle
            }
        }
    }
}

public extension Animation {
    static let pistolIdle = Animation(frames: [
        .pistol
    ], duration: 0)
    static let pistolFire = Animation(frames: [
        .pistolFire1,
        .pistolFire2,
        .pistolFire3,
        .pistolFire4,
        .pistol
    ], duration: 0.5)
}
