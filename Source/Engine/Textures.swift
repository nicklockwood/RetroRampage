//
//  Textures.swift
//  Engine
//
//  Created by Nick Lockwood on 05/06/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

public enum Texture: String, CaseIterable {
    case wall, wall2
    case crackWall, crackWall2
    case slimeWall, slimeWall2
    case floor
    case crackFloor
    case ceiling
    case monster
    case monsterWalk1, monsterWalk2
    case monsterScratch1, monsterScratch2, monsterScratch3, monsterScratch4
    case monsterScratch5, monsterScratch6, monsterScratch7, monsterScratch8
}

public struct Textures {
    private let textures: [Texture: Bitmap]
}

public extension Textures {
    init(loader: (String) -> Bitmap) {
        var textures = [Texture: Bitmap]()
        for texture in Texture.allCases {
            textures[texture] = loader(texture.rawValue)
        }
        self.init(textures: textures)
    }

    subscript(_ texture: Texture) -> Bitmap {
        return textures[texture]!
    }
}
