//
//  Input.swift
//  Engine
//
//  Created by Nick Lockwood on 03/06/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

public struct Input {
    public var speed: Double
    public var rotation: Rotation
    public var isFiring: Bool

    public init(speed: Double, rotation: Rotation, isFiring: Bool) {
        self.speed = speed
        self.rotation = rotation
        self.isFiring = isFiring
    }
}
