//
//  HUD.swift
//  Engine
//
//  Created by Nick Lockwood on 19/04/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

public struct HUD: View {
    public var position: Vector
    public let size: Vector
    public let subviews: [View]
    public let scale: Double

    public init(player: Player, window: Window, font: Font) {
        self.scale = window.size.y / 64
        self.position = window.safeArea.min / scale + Vector(x: 1, y: 1)
        self.size = window.safeArea.size / scale - Vector(x: 2, y: 2)

        let health = Int(max(0, player.health))
        let healthTint: Color
        switch health {
        case ...10:
            healthTint = .red
        case 10 ... 30:
            healthTint = .yellow
        default:
            healthTint = .green
        }
        let healthString = String(health)
        let ammoString = String(Int(max(0, min(99, player.ammo))))
        let playerWeapon = player.animation.texture
        let weaponIcon = player.weapon.attributes.hudIcon

        self.subviews = [
            // Reticle
            Image(texture: .crosshair, size: size, scalingMode: .center(scale: 1)),
            // Player weapon
            Image(
                texture: playerWeapon,
                size: window.size / scale,
                scalingMode: .aspectFit
            ),
            // HUD
            HStack(width: size.x, subviews: [
                // Left HUD
                HStack(subviews: [
                    Image(texture: .healthIcon, size: Vector(x: 6, y: 6)),
                    Text(text: healthString, font: font, tint: healthTint),
                ]),
                // Right HUD
                HStack(subviews: [
                    Image(texture: weaponIcon, size: Vector(x: 15, y: 6)),
                    Text(text: ammoString, font: font),
                    Spacer(size: 4),
                    Button(action: .pause, view: Image(
                        texture: .pauseButton,
                        size: Vector(x: 6, y: 6)
                    ))
                ]),
            ])
        ]
    }
}
