//
//  Monster.swift
//  Engine
//
//  Created by Nick Lockwood on 02/06/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

public enum MonsterState: Int, Codable {
    case idle
    case chasing
    case scratching
}

public struct Monster: Actor {
    public let speed: Double = 0.5
    public let radius: Double = 0.4375
    public var position: Vector
    public var velocity: Vector = Vector(x: 0, y: 0)
    public var state: MonsterState = .idle
    public var animation: Animation = .monsterIdle

    public init(position: Vector) {
        self.position = position
    }
}

public extension Monster {
    mutating func update(in world: World) {
        switch state {
        case .idle:
            if canSeePlayer(in: world) {
                state = .chasing
                animation = .monsterWalk
            }
            velocity = Vector(x: 0, y: 0)
        case .chasing:
            guard canSeePlayer(in: world) else {
                state = .idle
                animation = .monsterIdle
                break
            }
            if canReachPlayer(in: world) {
                state = .scratching
                animation = .monsterScratch
            }
            let direction = world.player.position - position
            velocity = direction * (speed / direction.length)
        case .scratching:
            guard canReachPlayer(in: world) else {
                state = .chasing
                animation = .monsterWalk
                break
            }
        }
    }

    func canSeePlayer(in world: World) -> Bool {
        let direction = world.player.position - position
        let playerDistance = direction.length
        let ray = Ray(origin: position, direction: direction / playerDistance)
        let wallHit = world.map.hitTest(ray)
        let wallDistance = (wallHit - position).length
        return wallDistance > playerDistance
    }

    func canReachPlayer(in world: World) -> Bool {
        let reach = 0.75
        let playerDistance = (world.player.position - position).length
        return playerDistance - world.player.radius < reach
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
}
