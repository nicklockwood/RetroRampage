//
//  Texture.swift
//  Engine
//
//  Created by Nick Lockwood on 13/02/2020.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

public enum Texture: String, CaseIterable, Decodable {
    case wall, wall2
    case crackWall, crackWall2
    case slimeWall, slimeWall2
    case door, door2
    case doorjamb, doorjamb2
    case floor
    case crackFloor
    case ceiling
    case monster
    case monsterWalk1, monsterWalk2
    case monsterScratch1, monsterScratch2, monsterScratch3, monsterScratch4
    case monsterScratch5, monsterScratch6, monsterScratch7, monsterScratch8
    case monsterHurt, monsterDeath1, monsterDeath2, monsterDead
    case pistol
    case pistolFire1, pistolFire2, pistolFire3, pistolFire4
    case shotgun
    case shotgunFire1, shotgunFire2, shotgunFire3, shotgunFire4
    case shotgunPickup
    case switch1, switch2, switch3, switch4
    case elevatorFloor, elevatorCeiling, elevatorSideWall, elevatorBackWall
    case medkit
    case crosshair
    case healthIcon
    case pistolIcon, shotgunIcon
    case font
    case titleBackground, titleLogo
}
