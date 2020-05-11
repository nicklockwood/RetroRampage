//
//  MapGenerator.swift
//  Engine
//
//  Created by Nick Lockwood on 09/05/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

public struct MapGenerator {
    public private(set) var map: Tilemap
    private var rng: RNG
    private var elevatorPosition: Vector!
    private var playerPosition: Vector!
    private var emptyTiles: [Vector] = []
    private var wallTiles: [Vector] = []

    public init(mapData: MapData, index: Int) {
        self.map = Tilemap(mapData, index: index)
        self.rng = RNG(seed: mapData.seed ?? .random(in: 0 ... .max))

        // Find empty tiles
        for y in 0 ..< map.height {
            for x in 0 ..< map.width {
                let position = Vector(x: Double(x) + 0.5, y: Double(y) + 0.5)
                if map[x, y].isWall {
                    if map[x, y] == .elevatorBackWall {
                        map[thing: x, y] = .switch
                    }
                    wallTiles.append(position)
                } else {
                    if map[x, y] == .elevatorFloor {
                        elevatorPosition = position
                    }
                    switch map[thing: x, y] {
                    case .nothing:
                        emptyTiles.append(position)
                    case .player:
                        playerPosition = position
                    default:
                        break
                    }
                }
            }
        }

        // Add doors
        for position in emptyTiles {
            let x = Int(position.x), y = Int(position.y)
            let left = map[x - 1, y], right = map[x + 1, y],
                up = map[x, y - 1], down = map[x, y + 1]
            if (left.isWall && right.isWall && !up.isWall && !down.isWall)
                || (!left.isWall && !right.isWall && up.isWall && down.isWall) {
                add(.door, at: position)
            }
        }

        // Add push-walls
        for _ in 0 ..< (mapData.pushwalls ?? 0) {
            add(.pushwall, at: wallTiles.filter { position in
                let x = Int(position.x), y = Int(position.y)
                guard x > 0, x < map.width - 1, y > 0, y < map.height - 1 else {
                    return false // Outer wall
                }
                let left = map[x - 1, y], right = map[x + 1, y],
                    up = map[x, y - 1], down = map[x, y + 1]
                if left.isWall, right.isWall, !up.isWall, !down.isWall,
                    !map[x, y - 2].isWall, !map[x, y + 2].isWall {
                    return true
                }
                if !left.isWall, !right.isWall, up.isWall, down.isWall,
                    !map[x - 2, y].isWall, !map[x + 2, y].isWall {
                    return true
                }
                return false
            }.randomElement(using: &rng))
        }

        // Add player
        if playerPosition == nil {
            playerPosition = emptyTiles.filter {
                findPath(from: $0, to: elevatorPosition, maxDistance: 1000).isEmpty == false
            }.randomElement(using: &rng)
            add(.player, at: playerPosition)
        }

        // Add monsters
        for _ in 0 ..< (mapData.monsters ?? 0) {
            add(.monster, at: emptyTiles.filter {
                (playerPosition - $0).length > 2.5
            }.randomElement(using: &rng))
        }

        // Add medkits
        for _ in 0 ..< (mapData.medkits ?? 0) {
            add(.medkit, at: emptyTiles.randomElement(using: &rng))
        }

        // Add shotguns
        for _ in 0 ..< (mapData.shotguns ?? 0) {
            add(.shotgun, at: emptyTiles.randomElement(using: &rng))
        }
    }
}

private extension MapGenerator {
    mutating func add(_ thing: Thing, at position: Vector?) {
        if let position = position {
            map[thing: Int(position.x), Int(position.y)] = thing
            if let index = emptyTiles.lastIndex(of: position) {
                emptyTiles.remove(at: index)
            }
        }
    }
}

extension MapGenerator: Graph {
    public typealias Node = Vector

    public func nodesConnectedTo(_ node: Node) -> [Node] {
        return [
            Node(x: node.x - 1, y: node.y),
            Node(x: node.x + 1, y: node.y),
            Node(x: node.x, y: node.y - 1),
            Node(x: node.x, y: node.y + 1),
        ].filter { node in
            let x = Int(node.x), y = Int(node.y)
            return map[x, y].isWall == false
        }
    }

    public func estimatedDistance(from a: Node, to b: Node) -> Double {
        return abs(b.x - a.x) + abs(b.y - a.y)
    }

    public func stepDistance(from a: Node, to b: Node) -> Double {
        return 1
    }
}
