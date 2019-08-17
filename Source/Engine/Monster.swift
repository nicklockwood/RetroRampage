//
//  Monster.swift
//  Engine
//
//  Created by Nick Lockwood on 02/06/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

public enum MonsterState {
    case idle
    case chasing
    case scratching
    case hurt
    case dead
}

public struct Monster: Actor {
    public let speed: Double = 0.5
    public let radius: Double = 0.4375
    public var position: Vector
    public var velocity: Vector = Vector(x: 0, y: 0)
    public var health: Double = 50
    public var state: MonsterState = .idle
    public var animation: Animation = .monsterIdle
    public let attackCooldown: Double = 0.4
    public private(set) var lastAttackTime: Double = 0

    public init(position: Vector) {
        self.position = position
    }
}

public extension Monster {
    var isDead: Bool {
        return health <= 0
    }

    mutating func update(in world: inout World) {
        switch state {
        case .idle:
            if canSeePlayer(in: world) {
                state = .chasing
                animation = .monsterWalk
            }
        case .chasing:
            guard canSeePlayer(in: world) else {
                state = .idle
                animation = .monsterIdle
                velocity = Vector(x: 0, y: 0)
                break
            }
            if canReachPlayer(in: world) {
                state = .scratching
                animation = .monsterScratch
                lastAttackTime = -attackCooldown
                velocity = Vector(x: 0, y: 0)
                break
            }
            let direction = world.player.position - position
            velocity = direction * (speed / direction.length)
        case .scratching:
            guard canReachPlayer(in: world) else {
                state = .chasing
                animation = .monsterWalk
                break
            }
            if animation.time - lastAttackTime >= attackCooldown {
                lastAttackTime = animation.time
                world.hurtPlayer(10)
            }
        case .hurt:
            if animation.isCompleted {
                state = .idle
                animation = .monsterIdle
            }
        case .dead:
            if animation.isCompleted {
                animation = .monsterDead
            }
        }
    }

    func canSeePlayer(in world: World) -> Bool {
        let direction = world.player.position - position
        let playerDistance = direction.length
        let ray = Ray(origin: position, direction: direction / playerDistance)
        let wallHit = world.hitTest(ray)
        let wallDistance = (wallHit - position).length
        return wallDistance > playerDistance
    }

    func canReachPlayer(in world: World) -> Bool {
        let reach = 0.75
        let playerDistance = (world.player.position - position).length
        return playerDistance - world.player.radius < reach
    }

    func billboard(for ray: Ray) -> Billboard {
        let plane = ray.direction.orthogonal
        return Billboard(
            start: position - plane / 2,
            direction: plane,
            length: 1,
            texture: animation.texture
        )
    }

    func hitTest(_ ray: Ray) -> Vector? {
        guard isDead == false, let hit = billboard(for: ray).hitTest(ray) else {
            return nil
        }
        guard (hit - position).length < radius else {
            return nil
        }
        return hit
    }
}

public extension Animation {
    static let monsterIdle = Animation(frames: [
        .monster
    ], duration: 0)
    static let monsterWalk = Animation(frames: [
        .monsterWalk1,
        .monster,
        .monsterWalk2,
        .monster
    ], duration: 0.5)
    static let monsterScratch = Animation(frames: [
        .monsterScratch1,
        .monsterScratch2,
        .monsterScratch3,
        .monsterScratch4,
        .monsterScratch5,
        .monsterScratch6,
        .monsterScratch7,
        .monsterScratch8,
    ], duration: 0.8)
    static let monsterHurt = Animation(frames: [
        .monsterHurt
    ], duration: 0.2)
    static let monsterDeath = Animation(frames: [
        .monsterHurt,
        .monsterDeath1,
        .monsterDeath2
    ], duration: 0.5)
    static let monsterDead = Animation(frames: [
        .monsterDead
    ], duration: 0)
}
