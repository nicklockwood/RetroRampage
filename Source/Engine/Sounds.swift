//
//  Sounds.swift
//  Engine
//
//  Created by Nick Lockwood on 11/11/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

public enum SoundName: String, CaseIterable {
    case pistolFire
    case ricochet
    case monsterHit
    case monsterGroan
    case monsterDeath
    case monsterSwipe
    case doorSlide
    case wallSlide
    case wallThud
    case switchFlip
    case playerDeath
    case playerWalk
    case squelch
}

public struct Sound {
    public let name: SoundName?
    public let channel: Int?
    public let volume: Double
    public let pan: Double
    public let delay: Double
}
