//
//  Billboard.swift
//  Engine
//
//  Created by Nick Lockwood on 05/06/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

public struct Billboard {
    var start: Vector
    var direction: Vector
    var length: Double
    var texture: Texture

    public init(start: Vector, direction: Vector, length: Double, texture: Texture) {
        self.start = start
        self.direction = direction
        self.length = length
        self.texture = texture
    }
}

public extension Billboard {
    var end: Vector {
        return start + direction * length
    }

    func hitTest(_ ray: Ray) -> Vector? {
        var lhs = ray, rhs = Ray(origin: start, direction: direction)

        // Ensure rays are never exactly vertical
        let epsilon = 0.00001
        if abs(lhs.direction.x) < epsilon {
            lhs.direction.x = epsilon
        }
        if abs(rhs.direction.x) < epsilon {
            rhs.direction.x = epsilon
        }

        // Calculate slopes and intercepts
        let (slope1, intercept1) = lhs.slopeIntercept
        let (slope2, intercept2) = rhs.slopeIntercept

        // Check if slopes are parallel
        if slope1 == slope2 {
            return nil
        }

        // Find intersection point
        let x = (intercept1 - intercept2) / (slope2 - slope1)
        let y = slope1 * x + intercept1

        // Check intersection point is in range
        let distanceAlongRay = (x - lhs.origin.x) / lhs.direction.x
        if distanceAlongRay < 0 {
            return nil
        }
        let distanceAlongBillboard = (x - rhs.origin.x) / rhs.direction.x
        if distanceAlongBillboard < 0 || distanceAlongBillboard > length {
            return nil
        }

        return Vector(x: x, y: y)
    }
}
