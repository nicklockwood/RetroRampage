//
//  RNG.swift
//  Engine
//
//  Created by Nick Lockwood on 17/05/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

let multiplier: UInt64 = 6364136223846793005
let increment: UInt64 = 1442695040888963407

public struct RNG {
    private var seed: UInt64 = 0

    public init(seed: UInt64) {
        self.seed = seed
    }

    public mutating func next() -> UInt64 {
        seed = seed &* multiplier &+ increment
        return seed
    }
}

public extension Collection where Index == Int {
    func randomElement(using generator: inout RNG) -> Element? {
        if isEmpty {
            return nil
        }
        return self[startIndex + Index(generator.next() % UInt64(count))]
    }
}
