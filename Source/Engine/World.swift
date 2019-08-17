//
//  World.swift
//  Engine
//
//  Created by Nick Lockwood on 02/06/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

public struct World {
    public let map: Tilemap
    public private(set) var doors: [Door]
    public private(set) var monsters: [Monster]
    public private(set) var player: Player!
    public private(set) var effects: [Effect]

    public init(map: Tilemap) {
        self.map = map
        self.doors = []
        self.monsters = []
        self.effects = []
        reset()
    }
}

public extension World {
    var size: Vector {
        return map.size
    }

    mutating func update(timeStep: Double, input: Input) {
        // Update effects
        effects = effects.compactMap { effect in
            guard effect.time < effect.duration else {
                return nil
            }
            var effect = effect
            effect.time += timeStep
            return effect
        }

        // Update player
        if player.isDead == false {
            var player = self.player!
            player.animation.time += timeStep
            player.update(with: input, in: &self)
            player.position += player.velocity * timeStep
            self.player = player
        } else if effects.isEmpty {
            reset()
            effects.append(Effect(type: .fadeIn, color: .red, duration: 0.5))
            return
        }

        // Update monsters
        for i in 0 ..< monsters.count {
            var monster = monsters[i]
            monster.animation.time += timeStep
            monster.update(in: &self)
            monster.position += monster.velocity * timeStep
            monsters[i] = monster
        }

        // Update doors
        for i in 0 ..< doors.count {
            var door = doors[i]
            door.time += timeStep
            door.update(in: &self)
            doors[i] = door
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
            monster.avoidWalls(in: self)
            monsters[i] = monster
        }
        player.avoidWalls(in: self)
    }

    var sprites: [Billboard] {
        let ray = Ray(origin: player.position, direction: player.direction)
        return monsters.map { $0.billboard(for: ray) } + doors.map { $0.billboard }
    }

    mutating func hurtPlayer(_ damage: Double) {
        if player.isDead {
            return
        }
        player.health -= damage
        player.velocity = Vector(x: 0, y: 0)
        let color = Color(r: 255, g: 0, b: 0, a: 191)
        effects.append(Effect(type: .fadeIn, color: color, duration: 0.2))
        if player.isDead {
            effects.append(Effect(type: .fizzleOut, color: .red, duration: 2))
        }
    }

    mutating func hurtMonster(at index: Int, damage: Double) {
        var monster = monsters[index]
        if monster.isDead {
            return
        }
        monster.health -= damage
        monster.velocity = Vector(x: 0, y: 0)
        if monster.isDead {
            monster.state = .dead
            monster.animation = .monsterDeath
        } else {
            monster.state = .hurt
            monster.animation = .monsterHurt
        }
        monsters[index] = monster
    }

    mutating func reset() {
        self.monsters = []
        self.doors = []
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
                case .door:
                    precondition(y > 0 && y < map.height, "Door cannot be placed on map edge")
                    let isVertical = map[x, y - 1].isWall && map[x, y + 1].isWall
                    doors.append(Door(position: position, isVertical: isVertical))
                }
            }
        }
    }

    func hitTest(_ ray: Ray) -> Vector {
        var wallHit = map.hitTest(ray)
        var distance = (wallHit - ray.origin).length
        for door in doors {
            guard let hit = door.billboard.hitTest(ray) else {
                continue
            }
            let hitDistance = (hit - ray.origin).length
            guard hitDistance < distance else {
                continue
            }
            wallHit = hit
            distance = hitDistance
        }
        return wallHit
    }

    func pickMonster(_ ray: Ray) -> Int? {
        let wallHit = hitTest(ray)
        var distance = (wallHit - ray.origin).length
        var result: Int? = nil
        for i in monsters.indices {
            guard let hit = monsters[i].hitTest(ray) else {
                continue
            }
            let hitDistance = (hit - ray.origin).length
            guard hitDistance < distance else {
                continue
            }
            result = i
            distance = hitDistance
        }
        return result
    }

    func isDoor(at x: Int, _ y: Int) -> Bool {
        return map.things[y * map.width + x] == .door
    }
}
