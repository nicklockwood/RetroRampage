//
//  ViewController.swift
//  RampageMac
//
//  Created by Nick Lockwood on 29/10/2019.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

import Cocoa
import Engine
import Renderer

private let joystickRadius: Double = 40
private let maximumTimeStep: Double = 1 / 20
private let worldTimeStep: Double = 1 / 120

public func loadLevels() -> [Tilemap] {
    let jsonURL = Bundle.main.url(forResource: "Levels", withExtension: "json")!
    let jsonData = try! Data(contentsOf: jsonURL)
    let levels = try! JSONDecoder().decode([MapData].self, from: jsonData)
    return levels.enumerated().map { index, mapData in
        MapGenerator(mapData: mapData, index: index).map
    }
}

public func loadFont() -> Font {
    let jsonURL = Bundle.main.url(forResource: "Font", withExtension: "json")!
    let jsonData = try! Data(contentsOf: jsonURL)
    return try! JSONDecoder().decode(Font.self, from: jsonData)
}

public func loadTextures() -> Textures {
    return Textures(loader: { name in
        Bitmap(image: NSImage(named: name)!)!
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

enum Key: UInt16 {
    case space = 49 // fire
    case leftArrow = 123 // turn left
    case rightArrow = 124 // turn right
    case downArrow = 125 // backwards
    case upArrow = 126 // forwards

    // Not used
    case `return` = 36
    case tab = 48
    case backspace = 51
    case rightCommand = 54
    case leftCommand = 55
    case leftShift = 56
    case capsLock = 57
    case leftOption = 58
    case control = 59
    case rightShift = 60
    case rightOption = 61
    case fn = 63
}

class ViewController: NSViewController {
    private let imageView = NSImageView()

    private let textures = loadTextures()
    private var game = Game(levels: loadLevels(), font: loadFont())
    private var lastFrameTime = CACurrentMediaTime()
    private var lastFiredTime = 0.0
    private var keysDown = Set<Key>()

    override func viewDidLoad() {
        super.viewDidLoad()

        setUpAudio()
        setUpImageView()

        let timer = Timer(timeInterval: 1/60.0, repeats: true, block: update)
        RunLoop.main.add(timer, forMode: .common)

        NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            guard let self = self, let key = Key(rawValue: event.keyCode) else {
                // Unrecognized modifier key
                print(event.keyCode)
                return event
            }
            if self.keysDown.contains(key) {
                self.keysDown.remove(key)
            } else {
                self.keysDown.insert(key)
            }
            return nil
        }
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let key = Key(rawValue: event.keyCode) else {
                // Unrecognized key
                print(event.keyCode)
                return event
            }
            self?.keysDown.insert(key)
            return nil
        }
        NSEvent.addLocalMonitorForEvents(matching: .keyUp) { [weak self] event in
            if let key = Key(rawValue: event.keyCode) {
                self?.keysDown.remove(key)
            }
            return event
        }

        game.delegate = self
        game.titleText = "PRESS SPACE TO START"
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        update(nil)
    }

    private var inputVector: Vector {
        var vector = Vector(x: 0, y: 0)
        if keysDown.contains(.upArrow) {
            vector.y -= 1
        }
        if keysDown.contains(.downArrow) {
            vector.y += 1
        }
        if keysDown.contains(.leftArrow) {
            vector.x -= 1
        }
        if keysDown.contains(.rightArrow) {
            vector.x += 1
        }
        return vector
    }

    var isFiring: Bool {
        return keysDown.contains(.space)
    }

    func update(_ timer: Timer?) {
        let timestamp = CACurrentMediaTime()
        let timeStep = min(maximumTimeStep, timestamp - lastFrameTime)
        let inputVector = self.inputVector
        let rotation = inputVector.x * game.world.player.turningSpeed * worldTimeStep
        var input = Input(
            speed: -inputVector.y,
            rotation: Rotation(sine: sin(rotation), cosine: cos(rotation)),
            isFiring: self.isFiring
        )
        lastFrameTime = timestamp
        lastFiredTime = min(lastFiredTime, lastFrameTime)

        let worldSteps = (timeStep / worldTimeStep).rounded(.up)
        for _ in 0 ..< Int(worldSteps) {
            game.update(timeStep: timeStep / worldSteps, input: input)
            input.isFiring = false
        }

        let aspect = Double(view.bounds.width / view.bounds.height)
        let height = min(Int(view.bounds.height), 480), width = Int(Double(height) * aspect)
        var renderer = Renderer(width: width, height: height, textures: textures)
        renderer.draw(game)

        imageView.image = NSImage(bitmap: renderer.bitmap)
    }

    func setUpImageView() {
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        imageView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        imageView.widthAnchor.constraint(greaterThanOrEqualTo: view.widthAnchor).isActive = true
        imageView.heightAnchor.constraint(greaterThanOrEqualTo: view.heightAnchor).isActive = true
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.imageAlignment = .alignTopLeft
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
