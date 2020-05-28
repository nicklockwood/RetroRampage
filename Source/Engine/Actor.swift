//
//  Actor.swift
//  Engine
//
//  Created by Nick Lockwood on 09/07/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

public protocol Actor: Codable {
    var radius: Double { get }
    var position: Vector { get set }
    var isDead: Bool { get }
}

public extension Actor {
    var rect: Rect {
        let halfSize = Vector(x: radius, y: radius)
        return Rect(min: position - halfSize, max: position + halfSize)
    }

    func intersection(with map: Tilemap) -> Vector? {
        let minX = Int(rect.min.x), maxX = Int(rect.max.x)
        let minY = Int(rect.min.y), maxY = Int(rect.max.y)
        var largestIntersection: Vector?
        for y in minY ... maxY {
            for x in minX ... maxX where map[x, y].isWall {
                let wallRect = Rect(
                    min: Vector(x: Double(x), y: Double(y)),
                    max: Vector(x: Double(x + 1), y: Double(y + 1))
                )
                if let intersection = rect.intersection(with: wallRect),
                    intersection.length > largestIntersection?.length ?? 0 {
                    largestIntersection = intersection
                }
            }
        }
        return largestIntersection
    }

    func intersection(with door: Door) -> Vector? {
        return rect.intersection(with: door.rect)
    }

    func intersection(with pushwall: Pushwall) -> Vector? {
        return rect.intersection(with: pushwall.rect)
    }

    func intersection(with world: World) -> Vector? {
        if let intersection = intersection(with: world.map) {
            return intersection
        }
        for door in world.doors {
            if let intersection = intersection(with: door) {
                return intersection
            }
        }
        for pushwall in world.pushwalls where pushwall.position != position {
            if let intersection = intersection(with: pushwall) {
                return intersection
            }
        }
        return nil
    }

    func intersection(with actor: Actor) -> Vector? {
        if isDead || actor.isDead {
            return nil
        }
        return rect.intersection(with: actor.rect)
    }

    mutating func avoidWalls(in world: World) {
        var attempts = 10
        while attempts > 0, let intersection = intersection(with: world) {
            position -= intersection
            attempts -= 1
        }
    }

    func isStuck(in world: World) -> Bool {
        // If outside map
        if position.x < 1 || position.x > world.map.size.x - 1 ||
            position.y < 1 || position.y > world.map.size.y - 1 {
            return true
        }
        // If stuck in a wall
        if world.map[Int(position.x), Int(position.y)].isWall {
            return true
        }
        // If stuck in pushwall
        return world.pushwalls.contains(where: {
            abs(position.x - $0.position.x) < 0.6 && abs(position.y - $0.position.y) < 0.6
        })
    }
}
