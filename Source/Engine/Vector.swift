//
//  Vector.swift
//  Engine
//
//  Created by Nick Lockwood on 02/06/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

public struct Vector: Hashable, Decodable {
    public var x, y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public extension Vector {
    static let zero = Vector(x: 0, y: 0)

    init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let x = try container.decode(Double.self)
        let y = try container.decode(Double.self)
        self.init(x: x, y: y)
    }

    var orthogonal: Vector {
        return Vector(x: -y, y: x)
    }

    var length: Double {
        return (x * x + y * y).squareRoot()
    }

    func dot(_ rhs: Vector) -> Double {
        return x * rhs.x + y * rhs.y
    }

    static func + (lhs: Vector, rhs: Vector) -> Vector {
        return Vector(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static func - (lhs: Vector, rhs: Vector) -> Vector {
        return Vector(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    static func * (lhs: Vector, rhs: Double) -> Vector {
        return Vector(x: lhs.x * rhs, y: lhs.y * rhs)
    }

    static func / (lhs: Vector, rhs: Double) -> Vector {
        return Vector(x: lhs.x / rhs, y: lhs.y / rhs)
    }

    static func * (lhs: Double, rhs: Vector) -> Vector {
        return Vector(x: lhs * rhs.x, y: lhs * rhs.y)
    }

    static func / (lhs: Double, rhs: Vector) -> Vector {
        return Vector(x: lhs / rhs.x, y: lhs / rhs.y)
    }

    static func += (lhs: inout Vector, rhs: Vector) {
        lhs.x += rhs.x
        lhs.y += rhs.y
    }

    static func -= (lhs: inout Vector, rhs: Vector) {
        lhs.x -= rhs.x
        lhs.y -= rhs.y
    }

    static func *= (lhs: inout Vector, rhs: Double) {
        lhs.x *= rhs
        lhs.y *= rhs
    }

    static func /= (lhs: inout Vector, rhs: Double) {
        lhs.x /= rhs
        lhs.y /= rhs
    }

    static prefix func - (rhs: Vector) -> Vector {
        return Vector(x: -rhs.x, y: -rhs.y)
    }
}
