//
//  CoreAnimationView.swift
//  Rampage
//
//  Created by Nick Lockwood on 17/07/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

import UIKit
import Engine

enum Orientation {
    case up
    case down
    case forwards
    case backwards
    case left
    case right
}

class CoreAnimationView: UIView {
    private var layerPool: ArraySlice<CALayer> = []

    override class var layerClass: AnyClass {
        return CATransformLayer.self
    }

    func draw(_ game: Game) {
        // Fill layer pool
        layerPool = ArraySlice(layer.sublayers ?? [])

        // Disable implicit animations
        CATransaction.setDisableActions(true)

        switch game.state {
        case .title, .starting:
            // Background
            let background = UIImage(named: Texture.titleBackground.rawValue)!
            let aspectRatio = background.size.width / background.size.height
            let screenHeight = bounds.height
            let backgroundWidth = screenHeight * aspectRatio
            addLayer(for: background,
                     at: CGPoint(x: bounds.width / 2 - backgroundWidth / 2, y: 0),
                     size: CGSize(width: backgroundWidth, height: screenHeight))

            // Logo
            let logo = UIImage(named: Texture.titleLogo.rawValue)!
            let logoScale = bounds.height / logo.size.height / 2
            let logoSize = CGSize(width: logo.size.width * logoScale,
                                  height: logo.size.height * logoScale)
            let logoPosition = CGPoint(x: (bounds.width - logoSize.width) / 2,
                                       y: bounds.height * 0.15)
            addLayer(for: logo, at: logoPosition, size: logoSize)

            // Text
            let textScale = bounds.height / 64
            let font = UIImage(named: game.font.texture.rawValue)!
            let charSize = CGSize(width: font.size.width / CGFloat(game.font.characters.count),
                                  height: font.size.height)
            let textWidth = charSize.width * CGFloat(game.titleText.count) * textScale
            var offset = CGPoint(x: (bounds.width - textWidth) / 2, y: bounds.height * 0.75)
            for char in game.titleText {
                let index = game.font.characters.firstIndex(of: String(char)) ?? 0
                let step = Int(charSize.width)
                let xRange = index * step ..< (index + 1) * step
                addLayer(for: font, xRange: xRange, at: offset,
                         size: CGSize(width: charSize.width * textScale,
                                      height: charSize.height * textScale))
                offset.x += charSize.width * textScale
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

        // Remove unused layers
        layerPool.forEach { $0.removeFromSuperlayer() }
    }

    func draw(_ world: World) {
        // Transform view
        let scale = bounds.height
        var viewTransform = CATransform3DIdentity
        viewTransform.m34 = 1 / -scale
        viewTransform = CATransform3DTranslate(viewTransform, 0, 0, scale)
        let angle = atan2(world.player.direction.x, -world.player.direction.y)
        viewTransform = CATransform3DRotate(viewTransform, CGFloat(angle), 0, 1, 0)
        viewTransform = CATransform3DTranslate(
            viewTransform,
            CGFloat(-world.player.position.x) * scale,
            0,
            CGFloat(-world.player.position.y) * scale
        )
        layer.transform = viewTransform

        // Draw map
        let map = world.map
        for y in 0 ..< map.height {
            for x in 0 ..< map.width {
                let tile = map[x, y]
                let position = CGPoint(x: x, y: y)
                if tile.isWall {
                    if y > 0, !map[x, y - 1].isWall {
                        let texture = world.isDoor(at: x, y - 1) ? .doorjamb2 : tile.textures[1]
                        addLayer(for: texture, at: transform(for: position, .backwards))
                    }
                    if y < map.height - 1, !map[x, y + 1].isWall {
                        let texture = world.isDoor(at: x, y + 1) ? .doorjamb2 : tile.textures[1]
                        addLayer(for: texture, at: transform(for: position, .forwards))
                    }
                    if x > 0, !map[x - 1, y].isWall {
                        let texture = world.isDoor(at: x - 1, y) ? .doorjamb : tile.textures[0]
                        addLayer(for: texture, at: transform(for: position, .left))
                    }
                    if x < map.width - 1, !map[x + 1, y].isWall {
                        let texture = world.isDoor(at: x + 1, y) ? .doorjamb : tile.textures[0]
                        addLayer(for: texture, at: transform(for: position, .right))
                    }
                } else {
                    addLayer(for: tile.textures[0], at: transform(for: position, .up))
                    addLayer(for: tile.textures[1], at: transform(for: position, .down))
                }
            }
        }

        // Draw switches
        for y in 0 ..< map.height {
            for x in 0 ..< map.width {
                if let s = world.switch(at: x, y) {
                    let position = CGPoint(x: x, y: y)
                    let texture = s.animation.texture
                    if y > 0, !map[x, y - 1].isWall {
                        addLayer(for: texture, at: transform(for: position, .backwards))
                    }
                    if y < map.height - 1, !map[x, y + 1].isWall {
                        addLayer(for: texture, at: transform(for: position, .forwards))
                    }
                    if x > 0, !map[x - 1, y].isWall {
                        addLayer(for: texture, at: transform(for: position, .left))
                    }
                    if x < map.width - 1, !map[x + 1, y].isWall {
                        addLayer(for: texture, at: transform(for: position, .right))
                    }
                }
            }
        }

        // Draw sprites
        for sprite in world.sprites {
            let center = sprite.start + (sprite.end - sprite.start) / 2
            var spriteTransform = CATransform3DMakeTranslation(
                CGFloat(center.x) * scale,
                0,
                CGFloat(center.y) * scale
            )
            let angle = atan2(-sprite.direction.y, sprite.direction.x)
            spriteTransform = CATransform3DRotate(spriteTransform, CGFloat(angle), 0, 1, 0)
            addLayer(for: sprite.texture, at: spriteTransform, doubleSided: true)
        }
    }

    func draw(_ hud: HUD) {
        // Player weapon
        let weaponTexture = UIImage(named: hud.playerWeapon.rawValue)!
        let aspectRatio = weaponTexture.size.width / weaponTexture.size.height
        let screenHeight = bounds.height
        let weaponWidth = screenHeight * aspectRatio
        addLayer(for: weaponTexture,
                 at: CGPoint(x: bounds.width / 2 - weaponWidth / 2, y: 0),
                 size: CGSize(width: weaponWidth, height: screenHeight))

        // Crosshair
        let crosshair = UIImage(named: Texture.crosshair.rawValue)!
        let hudScale = bounds.height / 64
        let crosshairSize = CGSize(width: crosshair.size.width * hudScale,
                                   height: crosshair.size.height * hudScale)
        addLayer(for: crosshair,
                 at: CGPoint(x: (bounds.width - crosshairSize.width) / 2,
                             y: (bounds.height - crosshairSize.height) / 2),
                 size: crosshairSize)

        // Health icon
        let healthIcon = UIImage(named: Texture.healthIcon.rawValue)!
        var offset = CGPoint(x: safeAreaInsets.left + hudScale,
                             y: safeAreaInsets.top + hudScale)
        addLayer(for: healthIcon, at: offset,
                 size: CGSize(width: healthIcon.size.width * hudScale,
                              height: healthIcon.size.height * hudScale))
        offset.x += healthIcon.size.width * hudScale

        // Health
        let font = UIImage(named: hud.font.texture.rawValue)!
        let charSize = CGSize(width: font.size.width / CGFloat(hud.font.characters.count),
                              height: font.size.height)
        for char in hud.healthString {
            let index = hud.font.characters.firstIndex(of: String(char)) ?? 0
            let step = Int(charSize.width)
            let xRange = index * step ..< (index + 1) * step
            addLayer(for: font, xRange: xRange, at: offset,
                     size: CGSize(width: charSize.width * hudScale,
                                  height: charSize.height * hudScale))
            offset.x += charSize.width * hudScale
        }

        // Ammunition
        offset.x = bounds.width - safeAreaInsets.right
        for char in hud.ammoString.reversed() {
            let index = hud.font.characters.firstIndex(of: String(char)) ?? 0
            let step = Int(charSize.width)
            let xRange = index * step ..< (index + 1) * step
            offset.x -= charSize.width * hudScale
            addLayer(for: font, xRange: xRange, at: offset,
                     size: CGSize(width: charSize.width * hudScale,
                                  height: charSize.height * hudScale))
        }

        // Weapon icon
        let weaponIcon = UIImage(named: hud.weaponIcon.rawValue)!
        offset.x -= weaponIcon.size.width * hudScale
        addLayer(for: weaponIcon, at: offset,
                 size: CGSize(width: weaponIcon.size.width * hudScale,
                              height: weaponIcon.size.height * hudScale))
    }

    func draw(_ effect: Effect) {
        switch effect.type {
        case .fadeIn:
            addOverlay(color: effect.color, opacity: 1 - effect.progress)
        case .fadeOut, .fizzleOut:
            addOverlay(color: effect.color, opacity: effect.progress)
        }
    }

    func transform(for position: CGPoint, _ orientation: Orientation) -> CATransform3D {
        let scale = bounds.height
        var transform = CATransform3DMakeTranslation(position.x * scale, 0, position.y * scale)
        switch orientation {
        case .up:
            transform = CATransform3DTranslate(transform, 0.5 * scale, 0.5 * scale, 0.5 * scale)
            transform = CATransform3DRotate(transform, .pi / 2, 1, 0, 0)
        case .down:
            transform = CATransform3DTranslate(transform, 0.5 * scale, -0.5 * scale, 0.5 * scale)
            transform = CATransform3DRotate(transform, -.pi / 2, 1, 0, 0)
        case .backwards:
            transform = CATransform3DTranslate(transform, 0.5 * scale, 0, 0)
            transform = CATransform3DRotate(transform, .pi, 0, 1, 0)
        case .forwards:
            transform = CATransform3DTranslate(transform, 0.5 * scale, 0, scale)
        case .left:
            transform = CATransform3DTranslate(transform, 0, 0, 0.5 * scale)
            transform = CATransform3DRotate(transform, -.pi / 2, 0, 1, 0)
        case .right:
            transform = CATransform3DTranslate(transform, scale, 0, 0.5 * scale)
            transform = CATransform3DRotate(transform, .pi / 2, 0, 1, 0)
        }
        return transform
    }

    func addLayer() -> CALayer {
        var layer: CALayer! = layerPool.popFirst()
        if layer == nil {
            layer = CALayer()
            layer.magnificationFilter = .nearest
            layer.minificationFilter = .nearest
            layer.isDoubleSided = false
            self.layer.addSublayer(layer)
        }
        layer.contents = nil
        layer.contentsRect = CGRect(x: 0, y: 0, width: 1, height: 1)
        layer.backgroundColor = nil
        return layer
    }

    func addLayer(for image: UIImage?, at transform: CATransform3D, doubleSided: Bool = false) {
        let layer = addLayer()
        let aspectRatio = image.map { $0.size.width / $0.size.height } ?? 1
        let scale = bounds.height
        layer.bounds.size = CGSize(width: scale * aspectRatio, height: scale)
        layer.contents = image?.cgImage
        layer.position = CGPoint(x: bounds.midX, y: bounds.midY)
        layer.isDoubleSided = doubleSided
        layer.transform = transform
    }

    func addLayer(for texture: Texture, at transform: CATransform3D, doubleSided: Bool = false) {
        let image = UIImage(named: texture.rawValue)
        addLayer(for: image, at: transform, doubleSided: doubleSided)
    }

    func addLayer(for image: UIImage, xRange: Range<Int>? = nil,
                  at origin: CGPoint, size: CGSize) {
        let layer = addLayer()
        layer.transform = CATransform3DTranslate(
            CATransform3DInvert(self.layer.transform),
            origin.x - (bounds.size.width - size.width) / 2,
            origin.y - (bounds.size.height - size.height) / 2, 4900
        )
        layer.position = CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2)
        layer.bounds.size = size
        layer.contents = image.cgImage
        let epsilon = (0.01 / image.size.width)
        if let xRange = xRange {
            let start = CGFloat(xRange.lowerBound) / image.size.width + epsilon
            let end = CGFloat(xRange.upperBound) / image.size.width - epsilon
            layer.contentsRect = CGRect(x: start, y: 0, width: end - start, height: 1)
        }
    }

    func addOverlay(color: Color, opacity: Double) {
        let layer = addLayer()
        layer.transform = CATransform3DTranslate(
            CATransform3DInvert(self.layer.transform), 0, 0, 5000
        )
        layer.frame = bounds
        layer.backgroundColor = UIColor(
            red: CGFloat(color.r) / 255,
            green: CGFloat(color.g) / 255,
            blue: CGFloat(color.b) / 255,
            alpha: CGFloat(color.a) / 255 * CGFloat(opacity)
        ).cgColor
    }
}
