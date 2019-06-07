//
//  World.swift
//  Engine
//
//  Created by Nick Lockwood on 02/06/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

public struct World: Codable {
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
        player.velocity = player.direction * input.speed * player.speed
        player.position += player.velocity * timeStep

        // Update monsters
        for i in 0 ..< monsters.count {
            var monster = monsters[i]
            monster.update(in: self)
            monster.position += monster.velocity * timeStep
            monster.animation.time += timeStep
            monsters[i] = monster
        }

        // Handle collisions
        for i in 0 ..< monsters.count {
            var monster = monsters[i]
            if let intersection = player.intersection(with: monster) {
                player.position -= intersection / 2
                monster.position += intersection / 2
            }
            for j in i + 1 ..< monsters.count {
                if let intersection = monster.intersection(with: monsters[j]) {
                    monster.position -= intersection / 2
                    monsters[j].position += intersection / 2
                }
            }
            while let intersection = monster.intersection(with: map) {
                monster.position -= intersection
            }
            monsters[i] = monster
        }
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
                length: 1,
                texture: monster.animation.texture
            )
        }
    }
}
