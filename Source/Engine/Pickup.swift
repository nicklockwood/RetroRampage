//
//  Pickup.swift
//  Engine
//
//  Created by Nick Lockwood on 27/01/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

public enum PickupType {
    case medkit
    case shotgun
}

public struct Pickup: Actor {
    public let type: PickupType
    public var radius: Double = 0.5
    public var position: Vector

    public init(type: PickupType, position: Vector) {
        self.type = type
        self.position = position
    }
}

public extension Pickup {
    var isDead: Bool { return false }

    var texture: Texture {
        switch type {
        case .medkit:
            return .medkit
        case .shotgun:
            return .shotgunPickup
        }
    }

    func billboard(for ray: Ray) -> Billboard {
        let plane = ray.direction.orthogonal
        return Billboard(
            start: position - plane / 2,
            direction: plane,
            length: 1,
            texture: texture
        )
    }
}
