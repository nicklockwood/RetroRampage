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
    
    private let contentView: ContentView = ContentView()
    
    private let textures = loadTextures()
    private var world = World(map: loadMap())
    private var lastFrameTime = CACurrentMediaTime()
    
    private var imageView: UIImageView {
        return self.contentView.imageView
    }
    
    override func loadView() {
        self.view = contentView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink.add(to: .main, forMode: .common)
        
    }
    
    @objc func update(_ displayLink: CADisplayLink) {
        let timeStep = min(maximumTimeStep, displayLink.timestamp - lastFrameTime)
        let leftInputVector = self.contentView.leftJoystickInputVector
        let rightInputVector = self.contentView.rightJoystickInputVector
        
        let rotation = rightInputVector.x * world.player.turningSpeed * worldTimeStep
        let input = Input(
            speed: leftInputVector.orthogonal,
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
    
}

class ContentView: UIView {
    
    private(set) lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.layer.magnificationFilter = .nearest
        return imageView
    }()
    
    private let leftJoyStick = UIView()
    private let rightJoystick = UIView()
    
    let leftGestureRecognizer = UIPanGestureRecognizer()
    let rightGestureRecognizer = UIPanGestureRecognizer()
    
    var leftJoystickInputVector: Vector {
        switch leftGestureRecognizer.state {
        case .began, .changed:
            let translation = leftGestureRecognizer.translation(in: self)
            var vector = Vector(x: Double(translation.x), y: Double(translation.y))
            vector /= max(joystickRadius, vector.length)
            leftGestureRecognizer.setTranslation(CGPoint(
                x: vector.x * joystickRadius,
                y: vector.y * joystickRadius
            ), in: self)
            return vector
        default:
            return Vector(x: 0, y: 0)
        }
    }
    
    var rightJoystickInputVector: Vector {
        switch rightGestureRecognizer.state {
        case .began, .changed:
            let translation = rightGestureRecognizer.translation(in: self)
            var vector = Vector(x: Double(translation.x), y: Double(translation.y))
            vector /= max(joystickRadius, vector.length)
            rightGestureRecognizer.setTranslation(CGPoint(
                x: vector.x * joystickRadius,
                y: vector.y * joystickRadius
            ), in: self)
            return vector
        default:
            return Vector(x: 0, y: 0)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.addSubview(self.imageView)
        
        self.addSubview(self.leftJoyStick)
        self.addSubview(self.rightJoystick)
        
        self.leftJoyStick.addGestureRecognizer(self.leftGestureRecognizer)
        self.rightJoystick.addGestureRecognizer(self.rightGestureRecognizer)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let bounds = self.bounds
        
        self.imageView.frame = bounds
        
        self.leftJoyStick.frame = CGRect(origin: .zero,
                                         size: CGSize(width: bounds.width / 2, height: bounds.height))
        self.rightJoystick.frame = CGRect(origin: CGPoint(x: bounds.width / 2, y: 0),
                                          size: CGSize(width: bounds.width / 2, height: bounds.height))
    }
}
