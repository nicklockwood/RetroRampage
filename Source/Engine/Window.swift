//
//  Window.swift
//  Engine
//
//  Created by Nick Lockwood on 10/04/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

public struct Window {
    public var width, height: Int
    public var safeArea: Rect

    public var size: Vector {
        return Vector(x: Double(width), y: Double(height))
    }

    public init(width: Int, height: Int, safeArea: Rect) {
        self.width = width
        self.height = height
        self.safeArea = safeArea
    }
}
