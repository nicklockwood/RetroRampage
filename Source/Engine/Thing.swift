//
//  Thing.swift
//  Engine
//
//  Created by Nick Lockwood on 03/06/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

public enum Thing: Int, Decodable {
    case nothing
    case player
    case monster
    case door
    case pushwall
    case `switch`
    case medkit
    case shotgun
}
