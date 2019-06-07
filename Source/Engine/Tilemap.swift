//
//  Tilemap.swift
//  Engine
//
//  Created by Nick Lockwood on 03/06/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

public struct Tilemap: Codable {
    private let tiles: [Tile]
    public let things: [Thing]
    public let width: Int
}

public extension Tilemap {
    var height: Int {
        return tiles.count / width
    }

    var size: Vector {
        return Vector(x: Double(width), y: Double(height))
    }

    subscript(x: Int, y: Int) -> Tile {
        return tiles[y * width + x]
    }

    func tile(at position: Vector, from direction: Vector) -> Tile {
        var offsetX = 0, offsetY = 0
        if position.x.rounded(.down) == position.x {
            offsetX = direction.x > 0 ? 0 : -1
        }
        if position.y.rounded(.down) == position.y {
            offsetY = direction.y > 0 ? 0 : -1
        }
        return self[Int(position.x) + offsetX, Int(position.y) + offsetY]
    }

    func hitTest(_ ray: Ray) -> Vector {
        var position = ray.origin
        let slope = ray.direction.x / ray.direction.y
        repeat {
            let edgeDistanceX, edgeDistanceY: Double
            if ray.direction.x > 0 {
                edgeDistanceX = position.x.rounded(.down) + 1 - position.x
            } else {
                edgeDistanceX = position.x.rounded(.up) - 1 - position.x
            }
            if ray.direction.y > 0 {
                edgeDistanceY = position.y.rounded(.down) + 1 - position.y
            } else {
                edgeDistanceY = position.y.rounded(.up) - 1 - position.y
            }
            let step1 = Vector(x: edgeDistanceX, y: edgeDistanceX / slope)
            let step2 = Vector(x: edgeDistanceY * slope, y: edgeDistanceY)
            if step1.length < step2.length {
                position += step1
            } else {
                position += step2
            }
        } while tile(at: position, from: ray.direction).isWall == false
        return position
    }
}
