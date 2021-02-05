//
//  Rect.swift
//  Engine
//
//  Created by Nick Lockwood on 02/06/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

public struct Rect {
    public var min, max: Vector

    public init(min: Vector, max: Vector) {
        self.min = min
        self.max = max
    }
}

public extension Rect {
    static let zero = Rect(min: .zero, max: .zero)

    var size: Vector {
        return max - min
    }

    var center: Vector {
        return min + size / 2
    }

    var aspectRatio: Double {
        return size.x / size.y
    }

    init(position: Vector = .zero, size: Vector) {
        self.min = position
        self.max = min + size
    }

    init(center: Vector, size: Vector) {
        self.min = center - size / 2
        self.max = center + size / 2
    }

    func inset(by size: Vector) -> Rect {
        return Rect(min: min + size, max: max - size)
    }

    func aspectFit(_ rect: Rect) -> Rect {
        var size = rect.size
        if rect.aspectRatio > aspectRatio {
            size.x = size.y * aspectRatio
        } else {
            size.y = size.x / aspectRatio
        }
        return Rect(center: rect.center, size: size)
    }

    func aspectFill(_ rect: Rect) -> Rect {
        var size = rect.size
        if rect.aspectRatio < aspectRatio {
            size.x = size.y * aspectRatio
        } else {
            size.y = size.x / aspectRatio
        }
        return Rect(center: rect.center, size: size)
    }

    func containsPoint(_ point: Vector) -> Bool {
        return point.x >= min.x && point.x < max.x &&
            point.y >= min.y && point.y < max.y
    }

    func intersection(with rect: Rect) -> Vector? {
        let left = Vector(x: max.x - rect.min.x, y: 0)
        if left.x <= 0 {
            return nil
        }
        let right = Vector(x: min.x - rect.max.x, y: 0)
        if right.x >= 0 {
            return nil
        }
        let up = Vector(x: 0, y: max.y - rect.min.y)
        if up.y <= 0 {
            return nil
        }
        let down = Vector(x: 0, y: min.y - rect.max.y)
        if down.y >= 0 {
            return nil
        }
        return [left, right, up, down]
            .sorted(by: { $0.length < $1.length }).first
    }
}
