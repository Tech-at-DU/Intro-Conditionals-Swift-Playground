//
//  GameScene.swift
//  Conditionals
//
//  Created by Dion Larson on 6/2/16.
//  Copyright (c) 2016 Dion Larson. All rights reserved.
//

import SpriteKit

let carCategory: UInt32 = 1 << 1
let multiplier: Double =  5
var crashed = false

enum CarColor: String {
    case Blue, Yellow, Green
}

enum CarLane {
    case Left, Middle, Right
    
    func position(y: CGFloat) -> CGPoint {
        switch self {
        case .Left:
            return CGPoint(x: 65, y: 568+y)
        case .Middle:
            return CGPoint(x: 160, y: 568+y)
        case .Right:
            return CGPoint(x: 255, y: 568+y)
        }
    }
}

public enum PlaygroundStep {
    case SpeedUp, MaintainDistance, MaintainUntilClear
}

public class Car: SKSpriteNode {
    public var carSpeed: Double = 60.0 {
        didSet {
            if carSpeed < 0 { carSpeed = 0 }
        }
    }
    
    func distanceTo(car: Car) -> Double {
        return Double(car.position.y - self.position.y - 100) / multiplier
    }
    
    func updatePosition(dt: Double) {
        position = CGPoint(x: Double(position.x), y: Double(position.y) + carSpeed * 5 * dt)
    }
}

public func brake() {
    if !GameScene.carChanged {
        GameScene.car.carSpeed -= 1
        GameScene.carChanged = true
    }
}

public func accelerate() {
    if !GameScene.carChanged {
        GameScene.car.carSpeed += 1
        GameScene.carChanged = true
    }
}

public class GameScene: SKScene, SKPhysicsContactDelegate {
    
    public static var car: Car!
    var playerCar: Car!
    var otherCar0: Car!
    var otherCar1: Car!
    var otherCar2: Car!
    var roadsNode: SKNode!
    var road0: SKSpriteNode!
    var road1: SKSpriteNode!
    var cars = [Car]()
    var roads = [SKNode]()
    var distanceLabel: SKLabelNode!
    var distance = 116
    var previousDistance = 116
    var speedLabel: SKLabelNode!
    public var updateCar: ((Int, Int, Int)->()) = {_,_,_ in
        
    }
    
    var lastTimeInterval: CFTimeInterval = 0.0
    var lastSpeedUpdate: CFTimeInterval = 0.0
    var totalTime: CFTimeInterval = 0.0
    public static var carChanged = false
    var step: PlaygroundStep = .SpeedUp
    
    public class func setup(step: PlaygroundStep) -> SKView {
        let sceneView = SKView(frame: CGRect(x: 0, y: 0, width: 320, height: 568))
        sceneView.wantsLayer = true
        let scene = GameScene(fileNamed: "GameScene")!
        scene.scaleMode = .aspectFill
        
        sceneView.presentScene(scene)
        
        switch step {
        case .SpeedUp:
            scene.playerCar.carSpeed = 30
        case .MaintainDistance:
            scene.otherCar1.carSpeed = 50
        case .MaintainUntilClear:
            scene.otherCar1.carSpeed = 0
            scene.otherCar1.position = CGPoint(x: scene.otherCar1.position.x, y: scene.otherCar1.position.y + 200)
        }
        scene.step = step
        
        return sceneView
    }
    
    override public func didMove(to: SKView) {
        /* Setup your scene here */
      roadsNode = childNode(withName: "roadsNode")
        road0 = roadsNode.childNode(withName: "road0") as? SKSpriteNode
        road1 = roadsNode.childNode(withName: "road1") as? SKSpriteNode
        
        playerCar = roadsNode.childNode(withName: "playerCar") as? Car
        GameScene.car = playerCar
        otherCar0 = roadsNode.childNode(withName: "otherCar0") as? Car
        otherCar1 = roadsNode.childNode(withName: "otherCar1") as? Car
        otherCar1.physicsBody = SKPhysicsBody(circleOfRadius: 50, center: CGPoint(x: 0, y: 14))
        otherCar2 = roadsNode.childNode(withName: "otherCar2") as? Car
        
        camera = playerCar.childNode(withName: "camera") as? SKCameraNode
        distanceLabel = camera?.childNode(withName: "distanceLabel") as? SKLabelNode
        speedLabel = camera?.childNode(withName: "speedLabel") as? SKLabelNode
        
        cars = [playerCar, otherCar0, otherCar1, otherCar2]
        roads = [road0, road1]
        
        for car in cars {
            car.physicsBody?.contactTestBitMask = carCategory
        }
        
        physicsWorld.contactDelegate = self
    }
    
    public func didBeginContact(contact: SKPhysicsContact) {
        distanceLabel.text = "Crashed! :("
        
        if let car0 = contact.bodyA.node as? Car, let car1 = contact.bodyB.node as? Car {
            car0.carSpeed = 0.0
            car1.carSpeed = 0.0
            car0.removeAllActions()
            car1.removeAllActions()
            crashed = true
        }
    }
    
    override public func update(_ currentTime: CFTimeInterval) {
        /* Called before each frame is rendered */
        if lastTimeInterval == 0 {
            lastTimeInterval = currentTime
        }
        
        for car in cars {
          car.updatePosition(dt: currentTime - lastTimeInterval)
        }
        totalTime += currentTime - lastTimeInterval
        lastSpeedUpdate += currentTime - lastTimeInterval
        lastTimeInterval = currentTime
        
        if !crashed {
            if lastSpeedUpdate > 0.1 {
                if step == .MaintainUntilClear && otherCar1.carSpeed < 60 && totalTime > 14 {
                    otherCar1.carSpeed += 1
                } else if step == .MaintainUntilClear && otherCar1.carSpeed > 0 && totalTime > 10 {
                    otherCar1.carSpeed -= 2
                } else if step == .MaintainUntilClear && otherCar1.carSpeed < 70 && totalTime > 6 {
                    otherCar1.carSpeed += 1
                }
                
                updateCar(Int(playerCar.carSpeed), distance, previousDistance)
                lastSpeedUpdate = 0
                previousDistance = distance
            }
          distance = Int(playerCar.distanceTo(car: otherCar1))
            distanceLabel.text = "Distance: \(distance)"
        }
        
        speedLabel.text = "\(Int(playerCar.carSpeed)) mph"
        
        for road in roads {
          let pos = convertPoint(toView: road.position)
            if pos.y <= -568 {
                road.position = CGPoint(x: road.position.x, y: road.position.y + 2*567)
            }
        }
        
        GameScene.carChanged = false
    }
}
