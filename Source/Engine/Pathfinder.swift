//
//  Pathfinder.swift
//  Engine
//
//  Created by Nick Lockwood on 10/02/2020.
//  Copyright © 2020 Nick Lockwood. All rights reserved.
//

import Foundation

public protocol Graph {
    associatedtype Node: Hashable

    func nodesConnectedTo(_ node: Node) -> [Node]
    func estimatedDistance(from a: Node, to b: Node) -> Double
    func stepDistance(from a: Node, to b: Node) -> Double
}

private class Path<Node> {
    let head: Node
    let tail: Path?
    let distanceTravelled: Double
    let totalDistance: Double

    init(head: Node, tail: Path?, stepDistance: Double, remaining: Double) {
        self.head = head
        self.tail = tail
        self.distanceTravelled = (tail?.distanceTravelled ?? 0) + stepDistance
        self.totalDistance = distanceTravelled + remaining
    }

    var nodes: [Node] {
        var nodes = [head]
        var tail = self.tail
        while let path = tail {
            nodes.insert(path.head, at: 0)
            tail = path.tail
        }
        nodes.removeFirst()
        return nodes
    }
}

public extension Graph {
    func findPath(from start: Node, to end: Node, maxDistance: Double) -> [Node] {
        var visited = Set([start])
        var paths = [Path(
            head: start,
            tail: nil,
            stepDistance: 0,
            remaining: estimatedDistance(from: start, to: end)
        )]

        while let path = paths.popLast() {
            // Finish if goal reached
            if path.head == end {
                return path.nodes
            }

            // Get connected nodes
            for node in nodesConnectedTo(path.head) where !visited.contains(node) {
                visited.insert(node)
                let next = Path(
                    head: node,
                    tail: path,
                    stepDistance: stepDistance(from: path.head, to: node),
                    remaining: estimatedDistance(from: node, to: end)
                )
                // Skip this node if max distance exceeded
                if next.totalDistance > maxDistance {
                    break
                }
                // Insert shortest path last
                if let index = paths.firstIndex(where: {
                    $0.totalDistance <= next.totalDistance
                }) {
                    paths.insert(next, at: index)
                } else {
                    paths.append(next)
                }
            }
        }

        // Unreachable
        return []
    }
}
