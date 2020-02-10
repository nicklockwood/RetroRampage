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
    public private(set) var weapon: Weapon = .pistol
    public private(set) var ammo: Double
    public var animation: Animation
    public let soundChannel: Int

    public init(position: Vector, soundChannel: Int) {
        self.position = position
        self.velocity = Vector(x: 0, y: 0)
        self.direction = Vector(x: 1, y: 0)
        self.health = 100
        self.soundChannel = soundChannel
        self.animation = weapon.attributes.idleAnimation
        self.ammo = weapon.attributes.defaultAmmo
    }
}

public extension Player {
    var isDead: Bool {
        return health <= 0
    }

    var isMoving: Bool {
        return velocity.x != 0 || velocity.y != 0
    }

    var canFire: Bool {
        guard ammo > 0 else {
            return false
        }
        switch state {
        case .idle:
            return true
        case .firing:
            return animation.time >= weapon.attributes.cooldown
        }
    }

    mutating func setWeapon(_ weapon: Weapon) {
        self.weapon = weapon
        animation = weapon.attributes.idleAnimation
        ammo = weapon.attributes.defaultAmmo
    }

    mutating func inherit(from player: Player) {
        health = player.health
        setWeapon(player.weapon)
        ammo = player.ammo
    }

    mutating func update(with input: Input, in world: inout World) {
        let wasMoving = isMoving
        direction = direction.rotated(by: input.rotation)
        velocity = direction * input.speed * speed
        if input.isFiring, canFire {
            state = .firing
            ammo -= 1
            animation = weapon.attributes.fireAnimation
            world.playSound(weapon.attributes.fireSound, at: position)
            let projectiles = weapon.attributes.projectiles
            var hitPosition, missPosition: Vector?
            for _ in 0 ..< projectiles {
                let spread = weapon.attributes.spread
                let sine = Double.random(in: -spread ... spread)
                let cosine = (1 - sine * sine).squareRoot()
                let rotation = Rotation(sine: sine, cosine: cosine)
                let direction = self.direction.rotated(by: rotation)
                let ray = Ray(origin: position, direction: direction)
                if let index = world.pickMonster(ray) {
                    let damage = weapon.attributes.damage / Double(projectiles)
                    world.hurtMonster(at: index, damage: damage)
                    hitPosition = world.monsters[index].position
                } else {
                    missPosition = world.hitTest(ray)
                }
            }
            if let hitPosition = hitPosition {
                world.playSound(.monsterHit, at: hitPosition)
            }
            if let missPosition = missPosition {
                world.playSound(.ricochet, at: missPosition)
            }
        }
        switch state {
        case .idle:
            if ammo == 0 {
                setWeapon(.pistol)
            }
        case .firing:
            if animation.isCompleted {
                state = .idle
                animation = weapon.attributes.idleAnimation
            }
        }
        if isMoving, !wasMoving {
            world.playSound(.playerWalk, at: position, in: soundChannel)
        } else if !isMoving {
            world.playSound(nil, at: position, in: soundChannel)
        }
    }
}
