//
//  Rect.swift
//  Engine
//
//  Created by Nick Lockwood on 02/06/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

public struct Rect {
    var min, max: Vector

    public init(min: Vector, max: Vector) {
        self.min = min
        self.max = max
    }
}
