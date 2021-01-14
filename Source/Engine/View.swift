//
//  View.swift
//  Engine
//
//  Created by Nick Lockwood on 08/04/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

public enum UIAction {
    case pause
    case resume
    case quit
}

public protocol View {
    var position: Vector { get set }
    var size: Vector { get }
    var scale: Double { get }
    var subviews: [View] { get }

    func hitTest(_ point: Vector) -> View?
}

public extension View {
    var scale: Double {
        return 1
    }

    var subviews: [View] {
        return []
    }

    var frame: Rect {
        return Rect(position: position, size: size)
    }

    func hitTest(_ point: Vector) -> View? {
        let point = point - position
        for view in subviews {
            if let view = view.hitTest(point / view.scale) {
                return view
            }
        }
        return nil
    }
}

public enum ScalingMode {
    case center(scale: Double)
    case stretch
    case aspectFit
    case aspectFill
}

public struct Image: View {
    public var position: Vector
    public let size: Vector
    public let texture: Texture
    public var scalingMode: ScalingMode
    public let clipRect: Rect?
    public let tint: Color?

    public init(texture: Texture, size: Vector, scalingMode: ScalingMode = .aspectFit,
                clipRect: Rect? = nil, tint: Color? = nil) {
        self.position = .zero
        self.size = size
        self.texture = texture
        self.scalingMode = scalingMode
        self.tint = tint
        self.clipRect = clipRect
    }
}

public struct Text: View {
    public var position: Vector
    public let size: Vector
    public let text: String
    public let tint: Color?
    public private(set) var subviews: [View]

    public init(text: String, font: Font, tint: Color? = nil) {
        self.position = .zero
        self.text = text
        let stack = HStack(subviews: text.map { char in
            let index = font.characters.firstIndex(of: String(char)) ?? 0
            let origin = Vector(x: Double(index) * font.glyphSize.x, y: 0)
            let rect = Rect(min: origin, max: origin + font.glyphSize)
            return Image(
                texture: font.texture,
                size: font.glyphSize,
                scalingMode: .stretch,
                clipRect: rect,
                tint: tint
            )
        })
        self.subviews = stack.subviews
        self.size = stack.size
        self.tint = tint
    }
}

public struct ScaleView: View {
    public var position: Vector
    public var size: Vector
    public let scale: Double
    public let subviews: [View]

    public init(size: Vector, scale: Double, subviews: [View]) {
        self.position = .zero
        self.size = size
        self.scale = scale
        self.subviews = subviews
    }

    public init(size: Vector, virtualHeight: Double, subviews: [View]) {
        self.init(size: size, scale: size.y / virtualHeight, subviews: subviews)
    }
}

public struct Spacer: View {
    public var position: Vector
    public private(set) var size: Vector

    public init(size: Vector) {
        self.position = .zero
        self.size = size
    }

    public init(size: Double) {
        self.init(size: Vector(x: size, y: size))
    }
}

public struct Button: View {
    public var position: Vector
    public let size: Vector
    public let subviews: [View]
    public let action: UIAction

    public init(action: UIAction, view: View) {
        self.size = view.size
        self.subviews = [view]
        self.action = action
        self.position = .zero
    }

    public func hitTest(_ point: Vector) -> View? {
        return frame.containsPoint(point) ? self : nil
    }
}

public struct ZStack: View {
    public var position: Vector
    public let size: Vector
    public let subviews: [View]

    public init(subviews: [View]) {
        var frame = Rect.zero
        for view in subviews {
            frame.min.x = min(frame.min.x, view.frame.min.x)
            frame.min.y = min(frame.min.y, view.frame.min.y)
            frame.max.x = max(frame.max.x, view.frame.max.x)
            frame.max.y = max(frame.max.y, view.frame.max.y)
        }
        self.subviews = subviews
        self.position = frame.min
        self.size = frame.size
    }
}

public struct HStack: View {
    public var position: Vector
    public private(set) var size: Vector
    public private(set) var subviews: [View]

    public init(subviews: [View]) {
        self.position = .zero
        self.subviews = subviews
        var size = Vector.zero
        for i in self.subviews.indices {
            var view = self.subviews[i]
            view.position.x = size.x
            size.x += view.size.x
            size.y = max(size.y, view.size.y)
            self.subviews[i] = view
        }
        self.size = size
    }

    public init(width: Double, subviews: [View]) {
        self.init(subviews: subviews)
        let spacing = (width - size.x) / Double(max(subviews.count - 1, 1))
        for i in self.subviews.indices {
            self.subviews[i].position.x += spacing * Double(i)
        }
        size.x = width
    }
}

public struct VStack: View {
    public var position: Vector
    public private(set) var size: Vector
    public private(set) var subviews: [View]

    public init(width: Double? = nil, subviews: [View]) {
        self.position = .zero
        self.subviews = subviews
        var size = Vector.zero
        for i in self.subviews.indices {
            var view = self.subviews[i]
            view.position.y = size.y
            size.y += view.size.y
            size.x = max(size.x, view.size.x)
            self.subviews[i] = view
        }
        let width = width ?? size.x
        for i in self.subviews.indices {
            self.subviews[i].position.x += (width - subviews[i].size.x) / 2
        }
        size.x = width
        self.size = size
    }
}



