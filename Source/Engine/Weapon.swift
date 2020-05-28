//
//  Weapon.swift
//  Engine
//
//  Created by Nick Lockwood on 07/02/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

public enum Weapon: Int, Codable {
    case pistol
    case shotgun
}

public extension Weapon {
    struct Attributes {
        let idleAnimation: Animation
        let fireAnimation: Animation
        let fireSound: SoundName
        let damage: Double
        let cooldown: Double
        let projectiles: Int
        let spread: Double
        let defaultAmmo: Double
        public let hudIcon: Texture
    }

    var attributes: Attributes {
        switch self {
        case .pistol:
            return Attributes(
                idleAnimation: .pistolIdle,
                fireAnimation: .pistolFire,
                fireSound: .pistolFire,
                damage: 10,
                cooldown: 0.25,
                projectiles: 1,
                spread: 0,
                defaultAmmo: .infinity,
                hudIcon: .pistolIcon
            )
        case .shotgun:
            return Attributes(
                idleAnimation: .shotgunIdle,
                fireAnimation: .shotgunFire,
                fireSound: .shotgunFire,
                damage: 50,
                cooldown: 0.5,
                projectiles: 5,
                spread: 0.4,
                defaultAmmo: 10,
                hudIcon: .shotgunIcon
            )
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
    static let shotgunIdle = Animation(frames: [
        .shotgun
    ], duration: 0)
    static let shotgunFire = Animation(frames: [
        .shotgunFire1,
        .shotgunFire2,
        .shotgunFire3,
        .shotgunFire4,
        .shotgun
    ], duration: 0.5)
}
