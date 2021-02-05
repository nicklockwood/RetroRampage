//
//  Game.swift
//  Engine
//
//  Created by Nick Lockwood on 07/10/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

public protocol GameDelegate: AnyObject {
    func playSound(_ sound: Sound)
    func clearSounds()
}

public enum GameState {
    case title
    case starting
    case playing
    case paused
    case quitting
}

public struct Game {
    public weak var delegate: GameDelegate?
    public let levels: [Tilemap]
    public private(set) var world: World
    public private(set) var state: GameState
    public private(set) var transition: Effect?
    public private(set) var overlay: Effect?
    public private(set) var background: View?
    public private(set) var hud: View?
    public private(set) var menu: View?
    public let font: Font
    public var titleText = "TAP TO START"

    public init(levels: [Tilemap], font: Font) {
        self.state = .title
        self.levels = levels
        self.world = World(map: levels[0])
        self.font = font
    }
}

public extension Game {
    mutating func update(timeStep: Double, input: Input, window: Window) {
        guard let delegate = delegate else {
            return
        }

        // Update transition and overlay
        transition?.time += timeStep
        overlay?.time += timeStep

        // Update UI
        switch state {
        case .playing, .quitting:
            background = nil
            hud = HUD(player: world.player, window: window, font: font)
            menu = nil
        case .paused:
            background = nil
            hud = HUD(player: world.player, window: window, font: font)
            let width = 64 * window.size.x / window.size.y
            menu = ScaleView(size: window.size, virtualHeight: 64, subviews: [
                VStack(width: width, subviews: [
                    Spacer(size: 14),
                    Image(
                        texture: .paused,
                        size: Vector(x: width / 2, y: 24),
                        scalingMode: .aspectFit
                    ),
                    HStack(subviews: [
                        Button(action: .quit, view: Text(text: "QUIT", font: font)),
                        Spacer(size: 6),
                        Button(action: .resume, view: Text(text: "RESUME", font: font, tint: .yellow)),
                    ])
                ]),
            ])
        case .starting, .title:
            let scale = window.size.y / 128
            let aspect = window.size.x / window.size.y
            background = ZStack(subviews: [
                Image(texture: .titleBackground, size: window.size, scalingMode: .aspectFill),
                Image(texture: .titleLogo, size: window.size, scalingMode: .center(scale: scale)),
                ScaleView(size: window.size, virtualHeight: 64, subviews: [
                    VStack(width: aspect * 64, subviews: [
                        Spacer(size: 48),
                        Text(text: titleText, font: font, tint: .yellow)
                    ])
                ])
            ])
            hud = nil
            menu = nil
        }

        // Update state
        var action: UIAction?
        switch state {
        case .title:
            if input.press != nil {
                transition = Effect(type: .fadeOut, color: .black, duration: 0.5)
                state = .starting
            }
        case .starting:
            if transition?.isCompleted == true {
                transition = Effect(type: .fadeIn, color: .black, duration: 0.5)
                state = .playing
            }
        case .playing:
            if let pressed = input.press, let hud = hud,
               let button = hud.hitTest(pressed / hud.scale) as? Button {
                action = button.action
                break
            }
            if let action = world.update(timeStep: timeStep, input: input) {
                switch action {
                case .loadLevel(let index):
                    let index = index % levels.count
                    world.setLevel(levels[index])
                    delegate.clearSounds()
                case .playSounds(let sounds):
                    sounds.forEach(delegate.playSound)
                }
            }
        case .paused:
            if let pressed = input.press, let menu = menu,
               let button = menu.hitTest(pressed / menu.scale) as? Button {
                action = button.action
            }
        case .quitting:
            if transition?.isCompleted == true {
                delegate.clearSounds()
                world = World(map: levels[0])
                state = .title
                transition = Effect(
                    type: .fadeIn,
                    color: .black,
                    duration: 0.5
                )
            }
        }

        // UI actions
        switch action {
        case .pause:
            state = .paused
            overlay = Effect(
                type: .fadeOut,
                color: Color.black.withAlpha(128),
                duration: 0.5
            )
        case .quit:
            state = .quitting
            overlay = Effect(
                type: .fadeIn,
                color: Color.black.withAlpha(128),
                duration: 0.5
            )
            transition = Effect(
                type: .fadeOut,
                color: .black,
                duration: 0.5
            )
        case .resume:
            state = .playing
            overlay = Effect(
                type: .fadeIn,
                color: Color.black.withAlpha(128),
                duration: 0.5
            )
        case nil:
            break
        }
    }
}
