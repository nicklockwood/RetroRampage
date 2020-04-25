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
}

public struct Game {
    public weak var delegate: GameDelegate?
    public let levels: [Tilemap]
    public private(set) var world: World
    public private(set) var state: GameState
    public private(set) var transition: Effect?
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
    var hud: HUD {
        return HUD(player: world.player, font: font)
    }

    mutating func update(timeStep: Double, input: Input) {
        guard let delegate = delegate else {
            return
        }

        // Update transition
        if var effect = transition {
            effect.time += timeStep
            transition = effect
        }

        // Update state
        switch state {
        case .title:
            if input.isFiring {
                transition = Effect(type: .fadeOut, color: .black, duration: 0.5)
                state = .starting
            }
        case .starting:
            if transition?.isCompleted == true {
                transition = Effect(type: .fadeIn, color: .black, duration: 0.5)
                state = .playing
            }
        case .playing:
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
        }
    }
}
