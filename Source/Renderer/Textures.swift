//
//  Textures.swift
//  Renderer
//
//  Created by Nick Lockwood on 05/06/2019.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import Engine

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
