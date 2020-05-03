//
//  HUD.swift
//  Engine
//
//  Created by Nick Lockwood on 19/04/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

public struct HUD {
    public let healthString: String
    public let healthTint: Color
    public let ammoString: String
    public let rightWeapon: Texture
    public let leftWeapon: Texture?
    public let weaponIcon: Texture
    public let font: Font

    public init(player: Player, font: Font) {
        let health = Int(max(0, player.health))
        switch health {
        case ...10:
            self.healthTint = .red
        case 10 ... 30:
            self.healthTint = .yellow
        default:
            self.healthTint = .green
        }
        self.healthString = String(health)
        self.ammoString = String(Int(max(0, min(99, player.ammo))))
        self.rightWeapon = player.rightWeapon.animation.texture
        self.leftWeapon = player.leftWeapon.map { $0.animation.texture }
        self.weaponIcon = player.rightWeapon.attributes.hudIcon
        self.font = font
    }
}
