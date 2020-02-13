//
//  RampageTests.swift
//  RampageTests
//
//  Created by Nick Lockwood on 05/08/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

import XCTest
import Engine
import Rampage
import Renderer

class RampageTests: XCTestCase {
    let world = World(map: loadLevels()[0])
    let textures = loadTextures()

    func testRenderFrame() {
        self.measure {
            var renderer = Renderer(width: 1000, height: 1000, textures: textures)
            renderer.draw(world)
        }
    }
}
