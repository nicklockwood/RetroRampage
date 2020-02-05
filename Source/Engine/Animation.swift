//
//  Animation.swift
//  Engine
//
//  Created by Nick Lockwood on 11/07/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

public struct Animation {
    public let frames: [Texture]
    public let duration: Double
    public var time: Double = 0

    public init(frames: [Texture], duration: Double) {
        self.frames = frames
        self.duration = duration
    }
}

public extension Animation {
    var isCompleted: Bool {
        return time >= duration
    }

    var texture: Texture {
        guard duration > 0 else {
            return frames[0]
        }
        let t = time.truncatingRemainder(dividingBy: duration) / duration
        return frames[Int(Double(frames.count) * t)]
    }
}
