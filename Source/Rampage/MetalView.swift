//
//  MetalView.swift
//  Rampage
//
//  Created by Nick Lockwood on 03/02/2021.
//  Copyright © 2021 Nick Lockwood. All rights reserved.
//

import UIKit
import MetalKit
import Engine
import Renderer
import simd

let fizzle = Bitmap(height: 128, pixels: {
    var colors = [Color]()
    colors.reserveCapacity(128*128)
    for _ in 0 ..< 64 {
        for i: UInt8 in 0 ... 255 {
            colors.append(Color(r: 255, g: 255, b: 255, a: i))
        }
    }
    return colors.shuffled()
}())

class MetalView: MTKView {
    private lazy var renderer = Renderer(metalView: self)

    override init(frame: CGRect, device: MTLDevice?) {
        super.init(frame: frame, device: device)
        setUp()
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        device = device ?? MTLCreateSystemDefaultDevice()
        renderer?.mtkView(self, drawableSizeWillChange: drawableSize)
        isPaused = true
        delegate = renderer
    }

    func draw(_ game: Game) {
        renderer?.game = game
        draw()
    }
}

let alignedUniformsSize = (MemoryLayout<Uniforms>.size + 0xFF) & -0x100
let maxBuffersInFlight = 3

struct Vertex {
    var position: SIMD3<Float>
    var texcoord: SIMD2<Float> = SIMD2(0, 0)
    var color: SIMD4<UInt8> = SIMD4(255, 255, 255, 255)
}

extension CGPoint {
    init(_ vector: Vector) {
        self.init(x: vector.x, y: vector.y)
    }
}

extension Vector {
    init(_ point: CGPoint) {
        self.init(x: Double(point.x), y: Double(point.y))
    }
}

enum Orientation {
    case up
    case down
    case forwards
    case backwards
    case left
    case right
    case billboard(end: CGPoint)
    case view(size: CGSize, xRange: (Float, Float))
    case overlay(opacity: Double, effect: EffectType)
}

struct Quad {
    var texture: Texture!
    var position: CGPoint
    var orientation: Orientation
    var translucent: Bool = false
    var tintColor: Color = .white
}

private class Renderer: NSObject, MTKViewDelegate {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let dynamicUniformBuffer: MTLBuffer
    let pipelineState: MTLRenderPipelineState
    let orthoPipelineState: MTLRenderPipelineState
    let effectPipelineState: MTLRenderPipelineState
    let fizzlePipelineState: MTLRenderPipelineState
    let depthState: MTLDepthStencilState
    let spriteDepthState: MTLDepthStencilState
    let overlayDepthState: MTLDepthStencilState

    var uniformBufferOffset = 0
    var uniformBufferIndex = 0
    var uniforms: UnsafeMutablePointer<Uniforms>
    var projectionMatrix = matrix_float4x4()
    var textures = [Texture: MTLTexture]()
    var fizzleTexture: MTLTexture

    var vertexBuffer: MTLBuffer!

    var quads = [Quad]()
    var vertexData = [Vertex]()
    var viewTransform = matrix_identity_float4x4
    var orthoTransform = matrix_identity_float4x4
    var playerPosition: Vector?

    let inFlightSemaphore = DispatchSemaphore(value: maxBuffersInFlight)

    var bounds: CGSize = .zero
    var safeAreaInsets: UIEdgeInsets = .zero
    var game: Game?

    // MARK: Setup

    init?(metalView: MetalView) {
        guard let device = metalView.device,
              let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        self.device = device
        self.commandQueue = commandQueue

        let uniformBufferSize = alignedUniformsSize * maxBuffersInFlight
        guard let buffer = self.device.makeBuffer(
            length: uniformBufferSize,
            options: [MTLResourceOptions.storageModeShared]
        ) else {
            return nil
        }
        dynamicUniformBuffer = buffer
        dynamicUniformBuffer.label = "UniformBuffer"
        uniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents())
            .bindMemory(to: Uniforms.self, capacity: 1)

        metalView.depthStencilPixelFormat = .depth32Float_stencil8
        metalView.colorPixelFormat = .bgra8Unorm
        metalView.sampleCount = 1


        do {
            pipelineState = try Self.buildRenderPipelineWithDevice(
                device: device,
                vertexShader: "vertexShader",
                fragmentShader: "fragmentShader",
                metalKitView: metalView
            )

            orthoPipelineState = try Self.buildRenderPipelineWithDevice(
                device: device,
                vertexShader: "orthoVertexShader",
                fragmentShader: "fragmentShader",
                metalKitView: metalView
            )

            effectPipelineState = try Self.buildRenderPipelineWithDevice(
                device: device,
                vertexShader: "orthoVertexShader",
                fragmentShader: "effectFragmentShader",
                metalKitView: metalView
            )

            fizzlePipelineState = try Self.buildRenderPipelineWithDevice(
                device: device,
                vertexShader: "orthoVertexShader",
                fragmentShader: "fizzleFragmentShader",
                metalKitView: metalView
            )

            let depthStateDescriptor = MTLDepthStencilDescriptor()
            depthStateDescriptor.depthCompareFunction = MTLCompareFunction.lessEqual
            depthStateDescriptor.isDepthWriteEnabled = true
            guard let state = device.makeDepthStencilState(descriptor: depthStateDescriptor) else {
                return nil
            }
            depthState = state

            depthStateDescriptor.isDepthWriteEnabled = false
            guard let state2 = device.makeDepthStencilState(descriptor: depthStateDescriptor) else {
                return nil
            }
            spriteDepthState = state2

            depthStateDescriptor.depthCompareFunction = .always
            guard let state3 = device.makeDepthStencilState(descriptor: depthStateDescriptor) else {
                return nil
            }
            overlayDepthState = state3

            fizzleTexture = try Self.loadTexture(device: device, bitmap: fizzle)
        } catch {
            print("Unable to initialize Metal. Error info: \(error)")
            return nil
        }

        super.init()
    }

    // MARK: MKViewDelegate

    func draw(in view: MTKView) {
        _ = inFlightSemaphore.wait(timeout: DispatchTime.distantFuture)

        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let game = game else {
            return
        }

        commandBuffer.addCompletedHandler { [inFlightSemaphore] _ in
            inFlightSemaphore.signal()
        }

        guard let renderPassDescriptor = view.currentRenderPassDescriptor,
              let renderEncoder = commandBuffer
                .makeRenderCommandEncoder(descriptor: renderPassDescriptor),
              let drawable = view.currentDrawable
        else {
            return
        }

        updateDynamicBufferState()
        uniforms[0] = Uniforms(
            projectionMatrix: projectionMatrix,
            modelViewMatrix: Self.viewTransform(for: game.world),
            orthoMatrix: matrix_ortho(width: Float(bounds.width), height: Float(bounds.height))
        )

        quads.removeAll()
        draw(game)

        renderEncoder.setCullMode(.back)
        renderEncoder.setFrontFacing(.counterClockwise)
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setDepthStencilState(depthState)
        renderEncoder.setVertexBuffer(dynamicUniformBuffer, offset:uniformBufferOffset, index: BufferIndex.uniforms.rawValue)
        var sprites = [Quad]()
        for (textureID, quads) in sortByTexture(self.quads) {
            switch quads[0].orientation {
            case .view, .overlay:
                continue
            case .billboard,
                 _ where quads[0].translucent:
                sprites += quads
                continue
            default:
                break
            }
            if let texture = textures[textureID] ??
                (try? Renderer.loadTexture(device: device, textureName: textureID.rawValue)) {
                renderEncoder.setFragmentTexture(texture, index: TextureIndex.color.rawValue)
                textures[textureID] = texture
            }
            var vertexData = getVertexData(for: quads)
            vertexBuffer = device.makeBuffer(
                bytes: &vertexData,
                length: vertexData.count * MemoryLayout<Vertex>.stride,
                options: .storageModeShared
            )
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0,
                                         vertexCount: vertexData.count)
        }

        renderEncoder.setCullMode(.none)
        renderEncoder.setDepthStencilState(spriteDepthState)
        let playerPosition = game.world.player.position
        for quad in sprites.sorted(by: {
            (Vector($0.position) - playerPosition).length > (Vector($1.position) - playerPosition).length
        }) {
            let textureID = quad.texture!
            if let texture = textures[textureID] ?? (try? Renderer.loadTexture(device: device, textureName: textureID.rawValue)) {
                renderEncoder.setFragmentTexture(texture, index: TextureIndex.color.rawValue)
                textures[textureID] = texture
            }
            var vertexData = getVertexData(for: [quad])
            vertexBuffer = device.makeBuffer(
                bytes: &vertexData,
                length: vertexData.count * MemoryLayout<Vertex>.stride,
                options: .storageModeShared
            )
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0,
                                         vertexCount: vertexData.count)
        }

        renderEncoder.setRenderPipelineState(orthoPipelineState)
        renderEncoder.setVertexBuffer(dynamicUniformBuffer, offset:uniformBufferOffset, index: BufferIndex.uniforms.rawValue)
        renderEncoder.setDepthStencilState(overlayDepthState)
        for quad in quads.filter({
            if case .view = $0.orientation { return true } else { return false }
        }) {
            let textureID = quad.texture!
            if let texture = textures[textureID] ?? (try? Renderer.loadTexture(device: device, textureName: textureID.rawValue)) {
                renderEncoder.setFragmentTexture(texture, index: TextureIndex.color.rawValue)
                textures[textureID] = texture
            }
            var vertexData = getVertexData(for: [quad])
            vertexBuffer = device.makeBuffer(
                bytes: &vertexData,
                length: vertexData.count * MemoryLayout<Vertex>.stride,
                options: .storageModeShared
            )
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0,
                                         vertexCount: vertexData.count)
        }

        renderEncoder.setFragmentTexture(fizzleTexture, index: TextureIndex.color.rawValue)
        for quad in self.quads {
            guard case let .overlay(_, effect) = quad.orientation else {
                continue
            }
            switch effect {
            case .fizzleOut:
                renderEncoder.setRenderPipelineState(fizzlePipelineState)
            case .fadeIn, .fadeOut:
                renderEncoder.setRenderPipelineState(effectPipelineState)
            }
            var vertexData = getVertexData(for: [quad])
            vertexBuffer = device.makeBuffer(
                bytes: &vertexData,
                length: vertexData.count * MemoryLayout<Vertex>.stride,
                options: .storageModeShared
            )
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0,
                                         vertexCount: vertexData.count)
        }

        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        bounds = size
        let aspect = Float(size.width) / Float(size.height)
        projectionMatrix = matrix_perspective_right_hand(
            fovyRadians: radians_from_degrees(35),
            aspectRatio: aspect,
            nearZ: 0.1,
            farZ: 100
        )
    }

    // MARK: Drawing

    func draw(_ game: Game) {
        switch game.state {
        case .title, .starting:
            // Background
            let backgroundTexture = Texture.titleBackground
            let background = UIImage(named: backgroundTexture.rawValue)!
            let aspectRatio = background.size.width / background.size.height
            let screenHeight = bounds.height
            let backgroundWidth = screenHeight * aspectRatio
            quads.append(Quad(texture: backgroundTexture,
                              position: CGPoint(x: bounds.width / 2 - backgroundWidth / 2, y: 0),
                              orientation: .view(size: CGSize(width: backgroundWidth, height: screenHeight),
                                                 xRange: (0, 1))))

            // Logo
            let logoTexture = Texture.titleLogo
            let logo = UIImage(named: logoTexture.rawValue)!
            let logoScale = bounds.height / logo.size.height / 2
            let logoSize = CGSize(width: logo.size.width * logoScale,
                                  height: logo.size.height * logoScale)
            let logoPosition = CGPoint(x: (bounds.width - logoSize.width) / 2,
                                       y: bounds.height * 0.15)
            quads.append(Quad(texture: logoTexture, position: logoPosition, orientation: .view(size: logoSize,
                                                                                               xRange: (0, 1))))

            // Text
            let textScale = bounds.height / 64
            let fontTexture = game.font.texture
            let font = UIImage(named: fontTexture.rawValue)!
            let charSize = CGSize(width: font.size.width / CGFloat(game.font.characters.count),
                                  height: font.size.height)
            let textWidth = charSize.width * CGFloat(game.titleText.count) * textScale
            var offset = CGPoint(x: (bounds.width - textWidth) / 2, y: bounds.height * 0.75)
            for char in game.titleText {
                let index = game.font.characters.firstIndex(of: String(char)) ?? 0
                let step = Int(charSize.width)
                let xRange = (
                    Float(index * step) / Float(font.size.width),
                    Float((index + 1) * step) / Float(font.size.width)
                )
                quads.append(Quad(texture: fontTexture,
                                  position: offset,
                                  orientation: .view(size: CGSize(
                                      width: charSize.width * textScale,
                                      height: charSize.height * textScale
                                  ), xRange: xRange)))
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
    }

    func draw(_ world: World) {
        // Draw map
        let map = world.map
        for y in 0 ..< map.height {
            for x in 0 ..< map.width {
                let tile = map[x, y]
                let position = CGPoint(x: x, y: y)
                if tile.isWall {
                    if y > 0, !map[x, y - 1].isWall {
                        let texture = world.isDoor(at: x, y - 1) ? .doorjamb2 : tile.textures[1]
                        quads.append(Quad(texture: texture, position: position, orientation: .backwards))
                    }
                    if y < map.height - 1, !map[x, y + 1].isWall {
                        let texture = world.isDoor(at: x, y + 1) ? .doorjamb2 : tile.textures[1]
                        quads.append(Quad(texture: texture, position: position, orientation: .forwards))
                    }
                    if x > 0, !map[x - 1, y].isWall {
                        let texture = world.isDoor(at: x - 1, y) ? .doorjamb : tile.textures[0]
                        quads.append(Quad(texture: texture, position: position, orientation: .left))
                    }
                    if x < map.width - 1, !map[x + 1, y].isWall {
                        let texture = world.isDoor(at: x + 1, y) ? .doorjamb : tile.textures[0]
                        quads.append(Quad(texture: texture, position: position, orientation: .right))
                    }
                } else {
                    quads.append(Quad(texture: tile.textures[0], position: position, orientation: .up))
                    quads.append(Quad(texture: tile.textures[1], position: position, orientation: .down))
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
                        quads.append(Quad(texture: texture, position: position, orientation: .backwards,
                                          translucent: true))
                    }
                    if y < map.height - 1, !map[x, y + 1].isWall {
                        quads.append(Quad(texture: texture, position: position, orientation: .forwards,
                                          translucent: true))
                    }
                    if x > 0, !map[x - 1, y].isWall {
                        quads.append(Quad(texture: texture, position: position, orientation: .left,
                                          translucent: true))
                    }
                    if x < map.width - 1, !map[x + 1, y].isWall {
                        quads.append(Quad(texture: texture, position: position, orientation: .right,
                                          translucent: true))
                    }
                }
            }
        }

        // Draw sprites
        for sprite in world.sprites {
            quads.append(Quad(texture: sprite.texture,
                              position: CGPoint(sprite.start),
                              orientation: .billboard(end: CGPoint(sprite.end)),
                              translucent: true))
        }
    }

    func draw(_ hud: HUD) {
        // Player weapon
        let weaponTexture = hud.playerWeapon
        let weapon = UIImage(named: weaponTexture.rawValue)!
        let aspectRatio = weapon.size.width / weapon.size.height
        let screenHeight = bounds.height
        let weaponWidth = screenHeight * aspectRatio
        quads.append(Quad(texture: weaponTexture,
                          position: CGPoint(x: bounds.width / 2 - weaponWidth / 2, y: 0),
                          orientation: .view(size: CGSize(width: weaponWidth, height: screenHeight),
                                             xRange: (0, 1))))

        // Crosshair
        let crosshairTexture = Texture.crosshair
        let crosshair = UIImage(named: crosshairTexture.rawValue)!
        let hudScale = bounds.height / 64
        let crosshairSize = CGSize(width: crosshair.size.width * hudScale,
                                   height: crosshair.size.height * hudScale)
        quads.append(Quad(texture: crosshairTexture,
                          position: CGPoint(x: (bounds.width - crosshairSize.width) / 2,
                                            y: (bounds.height - crosshairSize.height) / 2),
                          orientation: .view(size: crosshairSize, xRange: (0, 1))))

        // Health icon
        let healthTexture = Texture.healthIcon
        let healthIcon = UIImage(named: healthTexture.rawValue)!
        var offset = CGPoint(x: safeAreaInsets.left + hudScale,
                             y: safeAreaInsets.top + hudScale)
        quads.append(Quad(texture: healthTexture, position: offset,
                          orientation: .view(size: CGSize(width: healthIcon.size.width * hudScale,
                                                          height: healthIcon.size.height * hudScale),
                                             xRange: (0, 1))))
        offset.x += healthIcon.size.width * hudScale

        // Health
        let fontTexture = hud.font.texture
        let font = UIImage(named: fontTexture.rawValue)!
        let charSize = CGSize(width: font.size.width / CGFloat(hud.font.characters.count),
                              height: font.size.height)
        let healthTint = hud.healthTint
        for char in hud.healthString {
            let index = hud.font.characters.firstIndex(of: String(char)) ?? 0
            let step = Int(charSize.width)
            let xRange = (Float(index * step) / Float(font.size.width),
                          Float((index + 1) * step) / Float(font.size.width))
            quads.append(Quad(texture: fontTexture, position: offset,
                              orientation: .view(size: CGSize(width: charSize.width * hudScale,
                                                              height: charSize.height * hudScale),
                                                 xRange: xRange),
                              tintColor: healthTint))
            offset.x += charSize.width * hudScale
        }

        // Ammunition
        offset.x = bounds.width - safeAreaInsets.right
        for char in hud.ammoString.reversed() {
            let index = hud.font.characters.firstIndex(of: String(char)) ?? 0
            let step = Int(charSize.width)
            let xRange = (Float(index * step) / Float(font.size.width),
                          Float((index + 1) * step) / Float(font.size.width))
            offset.x -= charSize.width * hudScale
            quads.append(Quad(texture: fontTexture, position: offset,
                              orientation: .view(size: CGSize(width: charSize.width * hudScale,
                                                              height: charSize.height * hudScale),
                                                 xRange: xRange)))
        }

        // Weapon icon
        let weaponIconTexture = hud.weaponIcon
        let weaponIcon = UIImage(named: weaponIconTexture.rawValue)!
        offset.x -= weaponIcon.size.width * hudScale
        quads.append(Quad(texture: weaponIconTexture, position: offset,
                          orientation: .view(size: CGSize(width: weaponIcon.size.width * hudScale,
                                                          height: weaponIcon.size.height * hudScale),
                                             xRange: (0, 1))))
    }

    func draw(_ effect: Effect) {
        switch effect.type {
        case .fadeIn:
            quads.append(Quad(texture: nil, position: .zero,
                        orientation: .overlay(opacity: 1 - effect.progress, effect: effect.type),
                        tintColor: effect.color))
        case .fadeOut, .fizzleOut:
            quads.append(Quad(texture: nil, position: .zero,
                        orientation: .overlay(opacity: effect.progress, effect: effect.type),
                        tintColor: effect.color))
        }
    }

    // MARK: Utilities

    func sortByTexture(_ quads: [Quad]) -> [Texture: [Quad]] {
        var groups = [Texture: [Quad]]()
        for quad in quads where quad.texture != nil {
            groups[quad.texture, default: []].append(quad)
        }
        return groups
    }

    func makeQuad(_ a: SIMD3<Float>, _ b: SIMD3<Float>, _ c: SIMD3<Float>,
                  _ d: SIMD3<Float>, u1: Float = 0, u2: Float = 1, color: Color) -> [Vertex] {
        let color = SIMD4<UInt8>(color.r, color.g, color.b, color.a)
        return [
            Vertex(position: a, texcoord: SIMD2(u1, 1), color: color),
            Vertex(position: b, texcoord: SIMD2(u2, 1), color: color),
            Vertex(position: c, texcoord: SIMD2(u2, 0), color: color),
            Vertex(position: c, texcoord: SIMD2(u2, 0), color: color),
            Vertex(position: d, texcoord: SIMD2(u1, 0), color: color),
            Vertex(position: a, texcoord: SIMD2(u1, 1), color: color),
        ]
    }

    func getVertexData(for quads: [Quad]) -> [Vertex] {
        var vertexData = [Vertex]()
        vertexData.reserveCapacity(quads.count * 6)
        for quad in quads {
            let x = Float(quad.position.x), y = Float(quad.position.y)
            switch quad.orientation {
            case .up:
                vertexData += makeQuad(
                    SIMD3(x + 0, -0.5, y + 1),
                    SIMD3(x + 1, -0.5, y + 1),
                    SIMD3(x + 1, -0.5, y),
                    SIMD3(x + 0, -0.5, y),
                    color: quad.tintColor
                )
            case .down:
                vertexData += makeQuad(
                    SIMD3(x + 0, 0.5, y),
                    SIMD3(x + 1, 0.5, y),
                    SIMD3(x + 1, 0.5, y + 1),
                    SIMD3(x + 0, 0.5, y + 1),
                    color: quad.tintColor
                )
            case .backwards:
                vertexData += makeQuad(
                    SIMD3(x + 1, -0.5, y),
                    SIMD3(x + 0, -0.5, y),
                    SIMD3(x + 0, 0.5, y),
                    SIMD3(x + 1, 0.5, y),
                    color: quad.tintColor
                )
            case .forwards:
                vertexData += makeQuad(
                    SIMD3(x + 0, -0.5, y + 1),
                    SIMD3(x + 1, -0.5, y + 1),
                    SIMD3(x + 1, 0.5, y + 1),
                    SIMD3(x + 0, 0.5, y + 1),
                    color: quad.tintColor
                )
            case .left:
                vertexData += makeQuad(
                    SIMD3(x, -0.5, y + 0),
                    SIMD3(x, -0.5, y + 1),
                    SIMD3(x, 0.5, y + 1),
                    SIMD3(x, 0.5, y + 0),
                    color: quad.tintColor
                )
            case .right:
                vertexData += makeQuad(
                    SIMD3(x + 1, -0.5, y + 1),
                    SIMD3(x + 1, -0.5, y + 0),
                    SIMD3(x + 1, 0.5, y + 0),
                    SIMD3(x + 1, 0.5, y + 1),
                    color: quad.tintColor
                )
            case .billboard(end: let end):
                let x2 = Float(end.x), y2 = Float(end.y)
                vertexData += makeQuad(
                    SIMD3(x, -0.5, y),
                    SIMD3(x2, -0.5, y2),
                    SIMD3(x2, 0.5, y2),
                    SIMD3(x, 0.5, y),
                    color: quad.tintColor
                )
            case .view(size: let size, xRange: let (u1, u2)):
                let x2 = x + Float(size.width), y2 = y + Float(size.height)
                vertexData += makeQuad(
                    SIMD3(x, y2, 0),
                    SIMD3(x2, y2, 0),
                    SIMD3(x2, y, 0),
                    SIMD3(x, y, 0),
                    u1: u1, u2: u2,
                    color: quad.tintColor
                )
            case .overlay(opacity: let opacity, _):
                let color = Color(
                    r: quad.tintColor.r,
                    g: quad.tintColor.g,
                    b: quad.tintColor.b,
                    a: UInt8(min(255, Double(quad.tintColor.a) * opacity))
                )
                let size = Float(max(bounds.width, bounds.height))
                vertexData += makeQuad(
                    SIMD3(0, 0, 0),
                    SIMD3(size, 0, 0),
                    SIMD3(size, size, 0),
                    SIMD3(0, size, 0),
                    color: color
                )
            }
        }
        return vertexData
    }

    static func buildRenderPipelineWithDevice(device: MTLDevice,
                                              vertexShader: String,
                                              fragmentShader: String,
                                              metalKitView: MTKView) throws -> MTLRenderPipelineState {
        /// Build a render state pipeline object

        let library = device.makeDefaultLibrary()

        let vertexFunction = library?.makeFunction(name: vertexShader)
        let fragmentFunction = library?.makeFunction(name: fragmentShader)

        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.label = "RenderPipeline"
        pipelineDescriptor.sampleCount = metalKitView.sampleCount
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction

        pipelineDescriptor.colorAttachments[0].pixelFormat = metalKitView.colorPixelFormat
        pipelineDescriptor.colorAttachments[0].isBlendingEnabled = true
        pipelineDescriptor.colorAttachments[0].sourceRGBBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].sourceAlphaBlendFactor = .sourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        pipelineDescriptor.depthAttachmentPixelFormat = metalKitView.depthStencilPixelFormat
        pipelineDescriptor.stencilAttachmentPixelFormat = metalKitView.depthStencilPixelFormat

        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }

    static func loadTexture(device: MTLDevice,
                           textureName: String) throws -> MTLTexture {
        /// Load texture data with optimal parameters for sampling
        let textureLoader = MTKTextureLoader(device: device)

        let textureLoaderOptions: [MTKTextureLoader.Option : Any] = [
            .textureUsage: MTLTextureUsage.shaderRead.rawValue,
            .textureStorageMode: MTLStorageMode.private.rawValue,
            .SRGB: false,
        ]

        return try textureLoader.newTexture(name: textureName,
                                            scaleFactor: 1.0,
                                            bundle: nil,
                                            options: textureLoaderOptions)
    }

    static func loadTexture(device: MTLDevice,
                            bitmap: Bitmap) throws -> MTLTexture {
        /// Load texture data with optimal parameters for sampling
        let textureLoader = MTKTextureLoader(device: device)

        let options: [MTKTextureLoader.Option : Any] = [
            .textureUsage: MTLTextureUsage.shaderRead.rawValue,
            .textureStorageMode: MTLStorageMode.private.rawValue,
            .SRGB: false,
        ]

        let image = UIImage(bitmap: bitmap)?.cgImage
        return try textureLoader.newTexture(cgImage: image!, options: options)
    }

    private func updateDynamicBufferState() {
        /// Update the state of our uniform buffers before rendering

        uniformBufferIndex = (uniformBufferIndex + 1) % maxBuffersInFlight

        uniformBufferOffset = alignedUniformsSize * uniformBufferIndex

        uniforms = UnsafeMutableRawPointer(dynamicUniformBuffer.contents() + uniformBufferOffset).bindMemory(to:Uniforms.self, capacity:1)
    }

    static func viewTransform(for world: World) -> matrix_float4x4 {
        let angle = atan2(world.player.direction.x, -world.player.direction.y)
        let rotation = matrix4x4_rotation(radians: Float(angle), axis: SIMD3(0, 1, 0))
        let translation = matrix4x4_translation(-Float(world.player.position.x), 0,
                                                -Float(world.player.position.y))
        return matrix_multiply(rotation, translation)
    }
}

// Generic matrix math utility functions
func matrix4x4_rotation(radians: Float, axis: SIMD3<Float>) -> matrix_float4x4 {
    let unitAxis = normalize(axis)
    let ct = cosf(radians)
    let st = sinf(radians)
    let ci = 1 - ct
    let x = unitAxis.x, y = unitAxis.y, z = unitAxis.z
    return matrix_float4x4.init(columns:(vector_float4(    ct + x * x * ci, y * x * ci + z * st, z * x * ci - y * st, 0),
                                         vector_float4(x * y * ci - z * st,     ct + y * y * ci, z * y * ci + x * st, 0),
                                         vector_float4(x * z * ci + y * st, y * z * ci - x * st,     ct + z * z * ci, 0),
                                         vector_float4(                  0,                   0,                   0, 1)))
}

func matrix4x4_translation(_ translationX: Float, _ translationY: Float, _ translationZ: Float) -> matrix_float4x4 {
    return matrix_float4x4.init(columns:(vector_float4(1, 0, 0, 0),
                                         vector_float4(0, 1, 0, 0),
                                         vector_float4(0, 0, 1, 0),
                                         vector_float4(translationX, translationY, translationZ, 1)))
}

func matrix4x4_scale(_ scaleX: Float, _ scaleY: Float) -> matrix_float4x4 {
    return matrix_float4x4.init(columns:(vector_float4(scaleX, 0, 0, 0),
                                         vector_float4(0, scaleY, 0, 0),
                                         vector_float4(0, 0, 1, 0),
                                         vector_float4(0, 0, 0, 1)))
}

func matrix_perspective_right_hand(fovyRadians fovy: Float, aspectRatio: Float, nearZ: Float, farZ: Float) -> matrix_float4x4 {
    let ys = 1 / tanf(fovy * 0.5)
    let xs = ys / aspectRatio
    let zs = farZ / (nearZ - farZ)
    return matrix_float4x4.init(columns:(vector_float4(xs,  0, 0,   0),
                                         vector_float4( 0, ys, 0,   0),
                                         vector_float4( 0,  0, zs, -1),
                                         vector_float4( 0,  0, zs * nearZ, 0)))
}

func matrix_ortho(width: Float, height: Float) -> matrix_float4x4 {
    return  matrix_multiply(matrix4x4_translation(-1, 1, 0), matrix4x4_scale(2 / width, -2 / height))
}

func radians_from_degrees(_ degrees: Float) -> Float {
    return (degrees / 180) * .pi
}
