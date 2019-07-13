//
//  World.swift
//  Engine
//
//  Created by Nick Lockwood on 02/06/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

public struct World {
    public let map: Tilemap
    public var monsters: [Monster]
    public var player: Player!

    public init(map: Tilemap) {
        self.map = map
        self.monsters = []
        for y in 0 ..< map.height {
            for x in 0 ..< map.width {
                let position = Vector(x: Double(x) + 0.5, y: Double(y) + 0.5)
                let thing = map.things[y * map.width + x]
                switch thing {
                case .nothing:
                    break
                case .player:
                    self.player = Player(position: position)
                case .monster:
                    monsters.append(Monster(position: position))
                }
            }
        }
    }
}

public extension World {
    var size: Vector {
        return map.size
    }

    mutating func update(timeStep: Double, input: Input) {
        player.direction = player.direction.rotated(by: input.rotation)
        let cosine = player.direction.cosine(to: player.initialDirection)
        let sine = (1 - cosine * cosine).squareRoot()
        let rotation: Rotation
        if player.direction.y <= 0 {
            rotation = Rotation(sine: -sine, cosine: cosine)
        } else {
            rotation = Rotation(sine: sine, cosine: cosine)
        }
        player.velocity = input.speed.rotated(by: rotation) * player.speed
        player.position += player.velocity * timeStep
        while let intersection = player.intersection(with: map) {
            player.position -= intersection
        }
    }

    var sprites: [Billboard] {
        let spritePlane = player.direction.orthogonal
        return monsters.map { monster in
            Billboard(
                start: monster.position - spritePlane / 2,
                direction: spritePlane,
                length: 1
            )
        }
    }
}
