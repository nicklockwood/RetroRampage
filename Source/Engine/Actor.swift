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
}

public extension Actor {
    var rect: Rect {
        let halfSize = Vector(x: radius, y: radius)
        return Rect(min: position - halfSize, max: position + halfSize)
    }

    func intersection(with map: Tilemap) -> Vector? {
        let playerRect = self.rect
        let minX = Int(playerRect.min.x), maxX = Int(playerRect.max.x)
        let minY = Int(playerRect.min.y), maxY = Int(playerRect.max.y)
        for y in minY ... maxY {
            for x in minX ... maxX where map[x, y].isWall {
                let wallRect = Rect(
                    min: Vector(x: Double(x), y: Double(y)),
                    max: Vector(x: Double(x + 1), y: Double(y + 1))
                )
                if let intersection = rect.intersection(with: wallRect) {
                    return intersection
                }
            }
        }
        return nil
    }

    func intersection(with actor: Actor) -> Vector? {
        return rect.intersection(with: actor.rect)
    }
}
