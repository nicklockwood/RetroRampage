//
//  Input.swift
//  Engine
//
//  Created by Nick Lockwood on 03/06/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

public struct Input {
    public var speed: Vector
    public var rotation: Rotation

    public init(speed: Vector, rotation: Rotation) {
        self.speed = speed
        self.rotation = rotation
    }
}
