//
//  Player.swift
//  Engine
//
//  Created by Nick Lockwood on 02/06/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

public struct Player: Actor {
    public let speed: Double = 2
    public let turningSpeed: Double = .pi
    public let radius: Double = 0.25
    public var position: Vector
    public var velocity: Vector
    public var direction: Vector
    public var health: Double
    public var leftWeapon: Weapon?
    public var rightWeapon: Weapon = Weapon(type: .pistol)
    public private(set) var ammo: Double
    public let soundChannel: Int

    public init(position: Vector, soundChannel: Int) {
        self.position = position
        self.velocity = Vector(x: 0, y: 0)
        self.direction = Vector(x: 1, y: 0)
        self.health = 100
        self.soundChannel = soundChannel
        self.ammo = rightWeapon.attributes.defaultAmmo
    }
}

public extension Player {
    var isDead: Bool {
        return health <= 0
    }

    var isMoving: Bool {
        return velocity.x != 0 || velocity.y != 0
    }

    var isFiring: Bool {
        return rightWeapon.state == .firing || leftWeapon?.state == .firing
    }

    mutating func setWeapon(_ weapon: WeaponType) {
        if rightWeapon.type == weapon {
            leftWeapon = Weapon(type: weapon)
            ammo += weapon.attributes.defaultAmmo
        } else {
            rightWeapon = Weapon(type: weapon)
            leftWeapon = nil
            ammo = weapon.attributes.defaultAmmo
        }
    }

    mutating func inherit(from player: Player) {
        health = player.health
        rightWeapon = Weapon(type: player.rightWeapon.type)
        leftWeapon = player.leftWeapon.map { Weapon(type: $0.type) }
        ammo = player.ammo
    }

    mutating func update(with input: Input, in world: inout World) {
        let wasMoving = isMoving
        direction = direction.rotated(by: input.rotation)
        velocity = direction * input.speed * speed
        if input.isFiring, ammo > 0, rightWeapon.fire() || leftWeapon?.fire() == true {
            ammo -= 1
            world.playSound(rightWeapon.attributes.fireSound, at: position)
            let projectiles = rightWeapon.attributes.projectiles
            var hitPosition, missPosition: Vector?
            for _ in 0 ..< projectiles {
                let spread = rightWeapon.attributes.spread
                let sine = Double.random(in: -spread ... spread)
                let cosine = (1 - sine * sine).squareRoot()
                let rotation = Rotation(sine: sine, cosine: cosine)
                let direction = self.direction.rotated(by: rotation)
                let ray = Ray(origin: position, direction: direction)
                if let index = world.pickMonster(ray) {
                    let damage = rightWeapon.attributes.damage / Double(projectiles)
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
        leftWeapon?.update(in: &world)
        if ammo < 2, leftWeapon?.state != .firing {
            leftWeapon = nil
        }
        rightWeapon.update(in: &world)
        if ammo == 0, rightWeapon.state == .idle, leftWeapon == nil {
            rightWeapon = Weapon(type: .pistol)
            leftWeapon = nil
            ammo = rightWeapon.attributes.defaultAmmo
        }
        if isMoving, !wasMoving {
            world.playSound(.playerWalk, at: position, in: soundChannel)
        } else if !isMoving {
            world.playSound(nil, at: position, in: soundChannel)
        }
    }
}
