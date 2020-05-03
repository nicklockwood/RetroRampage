//
//  Font.swift
//  Engine
//
//  Created by Nick Lockwood on 21/04/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

public struct Font: Decodable {
    public let texture: Texture
    public let characters: [String]
}
