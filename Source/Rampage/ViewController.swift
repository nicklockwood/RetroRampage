//
//  ViewController.swift
//  Rampage
//
//  Created by Nick Lockwood on 17/05/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

import UIKit
import Engine
import Renderer

private let joystickRadius: Double = 40
private let maximumTimeStep: Double = 1 / 20
private let worldTimeStep: Double = 1 / 120

public func loadLevels() -> [Tilemap] {
    let jsonURL = Bundle.main.url(forResource: "Levels", withExtension: "json")!
    let jsonData = try! Data(contentsOf: jsonURL)
    let levels = try! JSONDecoder().decode([MapData].self, from: jsonData)
    return levels.enumerated().map { Tilemap($0.element, index: $0.offset) }
}

public func loadFont() -> Font {
    let jsonURL = Bundle.main.url(forResource: "Font", withExtension: "json")!
    let jsonData = try! Data(contentsOf: jsonURL)
    return try! JSONDecoder().decode(Font.self, from: jsonData)
}

public func loadTextures() -> Textures {
    return Textures(loader: { name in
        Bitmap(image: UIImage(named: name)!)!
    })
}

public extension SoundName {
    var url: URL? {
        return Bundle.main.url(forResource: rawValue, withExtension: "mp3")
    }
}

func setUpAudio() {
    for name in SoundName.allCases {
        precondition(name.url != nil, "Missing mp3 file for \(name.rawValue)")
    }
    try? SoundManager.shared.activate()
    _ = try? SoundManager.shared.preload(SoundName.allCases[0].url!)
}

class ViewController: UIViewController {
    private let imageView = UIImageView()
    private let panGesture = UIPanGestureRecognizer()
    private let tapGesture = UITapGestureRecognizer()
    private let textures = loadTextures()
    private var game = Game(levels: loadLevels(), font: loadFont())
    private var lastFrameTime = CACurrentMediaTime()
    private var lastFiredTime = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if NSClassFromString("XCTestCase") != nil {
            return
        }

        setUpAudio()
        setUpImageView()

        let displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink.add(to: .main, forMode: .common)

        view.addGestureRecognizer(panGesture)
        panGesture.delegate = self

        view.addGestureRecognizer(tapGesture)
        tapGesture.addTarget(self, action: #selector(fire))
        tapGesture.delegate = self

        game.delegate = self
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }

    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
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
        let rotation = inputVector.x * game.world.player.turningSpeed * worldTimeStep
        var input = Input(
            speed: -inputVector.y,
            rotation: Rotation(sine: sin(rotation), cosine: cos(rotation)),
            isFiring: lastFiredTime > lastFrameTime
        )
        lastFrameTime = displayLink.timestamp
        lastFiredTime = min(lastFiredTime, lastFrameTime)

        let worldSteps = (timeStep / worldTimeStep).rounded(.up)
        for _ in 0 ..< Int(worldSteps) {
            game.update(timeStep: timeStep / worldSteps, input: input)
            input.isFiring = false
        }

        let width = Int(imageView.bounds.width), height = Int(imageView.bounds.height)
        var renderer = Renderer(width: width, height: height, textures: textures)
        let insets = self.view.safeAreaInsets
        renderer.safeArea = Rect(
            min: Vector(x: Double(insets.left), y: Double(insets.top)),
            max: renderer.bitmap.size - Vector(x: Double(insets.left), y: Double(insets.bottom))
        )
        renderer.draw(game)

        imageView.image = UIImage(bitmap: renderer.bitmap)
    }

    @objc func fire(_ gestureRecognizer: UITapGestureRecognizer) {
        lastFiredTime = CACurrentMediaTime()
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
}

extension ViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
}

extension ViewController: GameDelegate {
    func playSound(_ sound: Sound) {
        DispatchQueue.main.asyncAfter(deadline: .now() + sound.delay) {
            guard let url = sound.name?.url else {
                if let channel = sound.channel {
                    SoundManager.shared.clearChannel(channel)
                }
                return
            }
            try? SoundManager.shared.play(
                url,
                channel: sound.channel,
                volume: sound.volume,
                pan: sound.pan
            )
        }
    }

    func clearSounds() {
        SoundManager.shared.clearAll()
    }
}
