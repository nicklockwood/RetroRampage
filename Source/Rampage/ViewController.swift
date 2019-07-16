//
//  ViewController.swift
//  Rampage
//
//  Created by Nick Lockwood on 17/05/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

import UIKit
import Engine

private let joystickRadius: Double = 40
private let maximumTimeStep: Double = 1 / 20
private let worldTimeStep: Double = 1 / 120
private let savePath = "~/Documents/quicksave.json"

private func loadMap() -> Tilemap {
    let jsonURL = Bundle.main.url(forResource: "Map", withExtension: "json")!
    let jsonData = try! Data(contentsOf: jsonURL)
    return try! JSONDecoder().decode(Tilemap.self, from: jsonData)
}

private func loadTextures() -> Textures {
    return Textures(loader: { name in
        Bitmap(image: UIImage(named: name)!)!
    })
}

class ViewController: UIViewController {
    private let imageView = UIImageView()
    private let panGesture = UIPanGestureRecognizer()
    private let textures = loadTextures()
    private var world = World(map: loadMap())
    private var lastFrameTime = CACurrentMediaTime()

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpImageView()

        let displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink.add(to: .main, forMode: .common)

        view.addGestureRecognizer(panGesture)

        try? restoreState()
        NotificationCenter.default.addObserver(
            forName: UIApplication.willResignActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            try? self.saveState()
        }
    }

    private var inputVector: Vector {
        switch panGesture.state {
        case .began, .changed:
            let translation = panGesture.translation(in: view)
            var vector = Vector(x: Double(translation.x), y: Double(translation.y))
            vector /= max(joystickRadius, vector.length)
            panGesture.setTranslation(CGPoint(
                x: vector.x * joystickRadius,
                y: vector.y * joystickRadius
            ), in: view)
            return vector
        default:
            return Vector(x: 0, y: 0)
        }
    }

    @objc func update(_ displayLink: CADisplayLink) {
        let timeStep = min(maximumTimeStep, displayLink.timestamp - lastFrameTime)
        let inputVector = self.inputVector
        let rotation = inputVector.x * world.player.turningSpeed * worldTimeStep
        let input = Input(
            speed: -inputVector.y,
            rotation: Rotation(sine: sin(rotation), cosine: cos(rotation))
        )
        let worldSteps = (timeStep / worldTimeStep).rounded(.up)
        for _ in 0 ..< Int(worldSteps) {
            world.update(timeStep: timeStep / worldSteps, input: input)
        }
        lastFrameTime = displayLink.timestamp

        let width = Int(imageView.bounds.width), height = Int(imageView.bounds.height)
        var renderer = Renderer(width: width, height: height, textures: textures)
        renderer.draw(world)

        imageView.image = UIImage(bitmap: renderer.bitmap)
    }

    func setUpImageView() {
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        imageView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.layer.magnificationFilter = .nearest
    }

    func saveState() throws {
        let data = try JSONEncoder().encode(world)
        let url = URL(fileURLWithPath: (savePath as NSString).expandingTildeInPath)
        try data.write(to: url, options: .atomic)
    }

    func restoreState() throws {
        let url = URL(fileURLWithPath: (savePath as NSString).expandingTildeInPath)
        let data = try Data(contentsOf: url)
        world = try JSONDecoder().decode(World.self, from: data)
    }
}
