//
//  Renderer.swift
//  Engine
//
//  Created by Nick Lockwood on 02/06/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

import Engine

private let fizzle = (0 ..< 10000).shuffled()

public struct Renderer {
    public private(set) var bitmap: Bitmap
    private let textures: Textures
    public var safeArea: Rect

    public init(width: Int, height: Int, textures: Textures) {
        self.bitmap = Bitmap(width: width, height: height, color: .black)
        self.textures = textures
        self.safeArea = Rect(min: Vector(x: 0, y: 0), max: bitmap.size)
    }
}

public extension Renderer {
    mutating func draw(_ game: Game) {
        switch game.state {
        case .title, .starting:
            // Background
            let background = textures[.titleBackground]
            let backgroundScale = bitmap.size.y / background.size.y
            let backgroundSize = background.size * backgroundScale
            let backgroundPosition = (bitmap.size - backgroundSize) / 2
            bitmap.drawImage(background, at: backgroundPosition, size: backgroundSize)
            
            // Logo
            let logo = textures[.titleLogo]
            let logoScale = bitmap.size.y / logo.size.y / 2
            let logoSize = logo.size * logoScale
            let logoPosition = Vector(x: (bitmap.size.x - logoSize.x) / 2, y: bitmap.size.y * 0.15)
            bitmap.drawImage(logo, at: logoPosition, size: logoSize)

            // Text
            let textScale = bitmap.size.y / 64
            let font = textures[game.font.texture]
            let charSize = Vector(x: Double(font.width / game.font.characters.count), y: font.size.y)
            let textWidth = charSize.x * Double(game.titleText.count) * textScale
            var offset = Vector(x: (bitmap.size.x - textWidth) / 2, y: bitmap.size.y * 0.75)
            for char in game.titleText {
                let index = game.font.characters.firstIndex(of: String(char)) ?? 0
                let step = Int(charSize.x)
                let xRange = index * step ..< (index + 1) * step
                bitmap.drawImage(
                    font,
                    xRange: xRange,
                    at: offset,
                    size: charSize * textScale,
                    tint: .yellow
                )
                offset.x += charSize.x * textScale
            }
        case .playing:
            draw(game.world)
            draw(game.hud)

            // Effects
            for effect in game.world.effects {
                draw(effect)
            }
        }

        // Transition
        if let effect = game.transition {
            draw(effect)
        }
    }

    mutating func draw(_ world: World) {
        let focalLength = 1.0
        let viewWidth = Double(bitmap.width) / Double(bitmap.height)
        let viewPlane = world.player.direction.orthogonal * viewWidth
        let viewCenter = world.player.position + world.player.direction * focalLength
        let viewStart = viewCenter - viewPlane / 2

        // Cast rays
        let columns = bitmap.width
        let step = viewPlane / Double(columns)
        var columnPosition = viewStart
        for x in 0 ..< columns {
            let rayDirection = columnPosition - world.player.position
            let viewPlaneDistance = rayDirection.length
            let ray = Ray(
                origin: world.player.position,
                direction: rayDirection / viewPlaneDistance
            )
            let end = world.map.hitTest(ray)
            let wallDistance = (end - ray.origin).length

            // Draw wall
            let wallHeight = 1.0
            let distanceRatio = viewPlaneDistance / focalLength
            let perpendicular = wallDistance / distanceRatio
            let height = wallHeight * focalLength / perpendicular * Double(bitmap.height)
            let wallTexture: Bitmap
            let wallX: Double
            let (tileX, tileY) = world.map.tileCoords(at: end, from: ray.direction)
            let tile = world.map[tileX, tileY]
            if end.x.rounded(.down) == end.x {
                let neighborX = tileX + (ray.direction.x > 0 ? -1 : 1)
                if world.map[neighborX, tileY].isWall {
                    wallTexture = textures[tile.textures[1]]
                    wallX = end.x - end.x.rounded(.down)
                } else {
                    let isDoor = world.isDoor(at: neighborX, tileY)
                    wallTexture = textures[isDoor ? .doorjamb : tile.textures[0]]
                    wallX = end.y - end.y.rounded(.down)
                }
            } else {
                let neighborY = tileY + (ray.direction.y > 0 ? -1 : 1)
                let isDoor = world.isDoor(at: tileX, neighborY)
                wallTexture = textures[isDoor ? .doorjamb2 : tile.textures[1]]
                wallX = end.x - end.x.rounded(.down)
            }
            let textureX = Int(wallX * Double(wallTexture.width))
            let wallStart = Vector(x: Double(x), y: (Double(bitmap.height) - height) / 2 - 0.001)
            bitmap.drawColumn(textureX, of: wallTexture, at: wallStart, height: height)

            // Draw switch
            if let s = world.switch(at: tileX, tileY) {
                let switchTexture = textures[s.animation.texture]
                bitmap.drawColumn(textureX, of: switchTexture, at: wallStart, height: height)
            }

            // Draw floor and ceiling
            var floorTile: Tile!
            var floorTexture, ceilingTexture: Bitmap!
            let floorStart = Int(wallStart.y + height) + 1
            for y in min(floorStart, bitmap.height) ..< bitmap.height {
                let normalizedY = (Double(y) / Double(bitmap.height)) * 2 - 1
                let perpendicular = wallHeight * focalLength / normalizedY
                let distance = perpendicular * distanceRatio
                let mapPosition = ray.origin + ray.direction * distance
                let tileX = mapPosition.x.rounded(.down), tileY = mapPosition.y.rounded(.down)
                let tile = world.map[Int(tileX), Int(tileY)]
                if tile != floorTile {
                    floorTexture = textures[tile.textures[0]]
                    ceilingTexture = textures[tile.textures[1]]
                    floorTile = tile
                }
                let textureX = mapPosition.x - tileX, textureY = mapPosition.y - tileY
                bitmap[x, y] = floorTexture[normalized: textureX, textureY]
                bitmap[x, bitmap.height - 1 - y] = ceilingTexture[normalized: textureX, textureY]
            }

            // Sort sprites by distance
            var spritesByDistance: [(hit: Vector, distance: Double, sprite: Billboard)] = []
            for sprite in world.sprites {
                guard let hit = sprite.hitTest(ray) else {
                    continue
                }
                let spriteDistance = (hit - ray.origin).length
                if spriteDistance > wallDistance {
                    continue
                }
                spritesByDistance.append(
                    (hit: hit, distance: spriteDistance, sprite: sprite)
                )
            }
            spritesByDistance.sort(by: { $0.distance > $1.distance })

            // Draw sprites
            for (hit, spriteDistance, sprite) in spritesByDistance {
                let perpendicular = spriteDistance / distanceRatio
                let height = wallHeight / perpendicular * Double(bitmap.height)
                let spriteX = (hit - sprite.start).length / sprite.length
                let spriteTexture = textures[sprite.texture]
                let textureX = min(Int(spriteX * Double(spriteTexture.width)), spriteTexture.width - 1)
                let start = Vector(x: Double(x), y: (Double(bitmap.height) - height) / 2 + 0.001)
                bitmap.drawColumn(textureX, of: spriteTexture, at: start, height: height)
            }

            columnPosition += step
        }
    }

    mutating func draw(_ hud: HUD) {
        // Player weapon
        let weaponTexture = textures[hud.playerWeapon]
        let weaponScale = bitmap.size.y / weaponTexture.size.y
        let weaponSize = weaponTexture.size * weaponScale
        bitmap.drawImage(weaponTexture, at: (bitmap.size - weaponSize) / 2, size: weaponSize)

        // Crosshair
        let crosshair = textures[.crosshair]
        let hudScale = bitmap.size.y / 64
        let crosshairSize = crosshair.size * hudScale
        bitmap.drawImage(crosshair, at: (bitmap.size - crosshairSize) / 2, size: crosshairSize)

        // Health icon
        let healthIcon = textures[.healthIcon]
        var offset = safeArea.min + Vector(x: 1, y: 1) * hudScale
        bitmap.drawImage(healthIcon, at: offset, size: healthIcon.size * hudScale)
        offset.x += healthIcon.size.x * hudScale

        // Health
        let font = textures[hud.font.texture]
        let charSize = Vector(x: Double(font.width / hud.font.characters.count), y: font.size.y)
        let healthTint = hud.healthTint
        for char in hud.healthString {
            let index = hud.font.characters.firstIndex(of: String(char)) ?? 0
            let step = Int(charSize.x)
            let xRange = index * step ..< (index + 1) * step
            bitmap.drawImage(
                font,
                xRange: xRange,
                at: offset,
                size: charSize * hudScale,
                tint: healthTint
            )
            offset.x += charSize.x * hudScale
        }

        // Ammunition
        offset.x = safeArea.max.x
        for char in hud.ammoString.reversed() {
            let index = hud.font.characters.firstIndex(of: String(char)) ?? 0
            let step = Int(charSize.x)
            let xRange = index * step ..< (index + 1) * step
            offset.x -= charSize.x * hudScale
            bitmap.drawImage(font, xRange: xRange, at: offset, size: charSize * hudScale)
        }

        // Weapon icon
        let weaponIcon = textures[hud.weaponIcon]
        offset.x -= weaponIcon.size.x * hudScale
        bitmap.drawImage(weaponIcon, at: offset, size: weaponIcon.size * hudScale)
    }

    mutating func draw(_ effect: Effect) {
        switch effect.type {
        case .fadeIn:
            bitmap.tint(with: effect.color, opacity: 1 - effect.progress)
        case .fadeOut:
            bitmap.tint(with: effect.color, opacity: effect.progress)
        case .fizzleOut:
            let threshold = Int(effect.progress * Double(fizzle.count))
            for x in 0 ..< bitmap.width {
                for y in 0 ..< bitmap.height {
                    let granularity = 4
                    let index = y / granularity * bitmap.width + x / granularity
                    let fizzledIndex = fizzle[index % fizzle.count]
                    if fizzledIndex <= threshold {
                        bitmap[x, y] = effect.color
                    }
                }
            }
        }
    }
}
