//
//  GameViewController.swift
//  Crazy Road
//
//  Created by Edward Hu on 9/10/18.
//  Copyright © 2018 Edward Hu. All rights reserved.
//

import UIKit
import QuartzCore
import SceneKit
import SpriteKit

enum GameState {
    case menu, playing, gameOver
}

class GameViewController: UIViewController {

    var scene: SCNScene!
    var sceneView: SCNView!
    var gameHUD: GameHUD!
    var gameState = GameState.menu
    var score = 0
    
    var cameraNode = SCNNode()
    var lightNode = SCNNode()
    var playerNode = SCNNode()
    var collisionNode = CollisionNode()
    var mapNode = SCNNode()
    var lanes = [LaneNode]()
    var laneCount = 0
    
    var jumpForwardAction: SCNAction?
    var jumpRightAction: SCNAction?
    var jumpLeftAction: SCNAction?
    var jumpBackAction: SCNAction?
    var driveRightAction: SCNAction?
    var driveLeftAction: SCNAction?
    var dieAction: SCNAction?
    
    var frontBlocked = false
    var rightBlocked = false
    var leftBlocked = false
    var backBlocked = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initializeGame()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch gameState {
        case .menu:
            setupGestures()
            gameHUD = GameHUD(with: sceneView.bounds.size, menu: false)
            sceneView.overlaySKScene = gameHUD
            sceneView.overlaySKScene?.isUserInteractionEnabled = false
            gameState = .playing
        default:
            break
        }
    }
    
    func resetGame() {
        scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeFromParentNode()
        }
        scene = nil
        gameState = .menu
        score = 0
        laneCount = 0
        lanes = [LaneNode]()
        initializeGame()
    }
    
    func initializeGame() {
        setupScene()
        setupPlayer()
        setupCollisionNode()
        setupFloor()
        setupCamera()
        setupLight()
        setupActions()
        setupTraffic()
    }
    
    
    func setupScene() {
        sceneView = view as! SCNView
        sceneView.delegate = self //for SCNSceneRendererDelegate
        
        scene = SCNScene()
        scene.physicsWorld.contactDelegate = self
        sceneView.present(scene, with: .crossFade(withDuration: 0.0), incomingPointOfView: nil, completionHandler: nil)
        //sceneView.scene = scene
        
        DispatchQueue.main.async {
            self.gameHUD = GameHUD(with: self.sceneView.bounds.size, menu: true)
            self.sceneView.overlaySKScene = self.gameHUD
            self.sceneView.overlaySKScene?.isUserInteractionEnabled = false
        }
        
        scene.rootNode.addChildNode(mapNode)
        for _ in 0..<10 {
            createNewLane(initial: true)
        }
        
        for _ in 0..<10 {
            createNewLane(initial: false)
            
        }
    }
    
    func setupPlayer() {
        guard let playerScene = SCNScene(named: "art.scnassets/Chicken.scn") else {return}
        if let player = playerScene.rootNode.childNode(withName: "player", recursively: true) {
            playerNode = player
            playerNode.position = SCNVector3(x: 0, y: 0.3, z: 0)
            scene.rootNode.addChildNode(playerNode)
        }
    }
    
    func setupCollisionNode() {
        collisionNode = CollisionNode() //needed to reinitialize/reset when game restarts
        collisionNode.position = playerNode.position
        scene.rootNode.addChildNode(collisionNode)
    }
    
    func setupFloor() {
        let floor = SCNFloor()
        floor.firstMaterial?.diffuse.contents = UIImage(named: "art.scnassets/darkgrass.png")
        floor.firstMaterial?.diffuse.wrapS = .repeat
        floor.firstMaterial?.diffuse.wrapT = .repeat
        floor.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(12.5, 12.5, 12.5)
        floor.reflectivity = 0.0
        
        let floorNode = SCNNode(geometry: floor)
        scene.rootNode.addChildNode(floorNode)
    }
    
    func setupCamera() {
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 10, z: 0) //height of 10
        cameraNode.eulerAngles = SCNVector3(x: -toRadians(angle: 60), y: toRadians(angle: 20), z: 0) //rotate camera down 90 deg since default is looking straight
        scene.rootNode.addChildNode(cameraNode)
    }
    
    func setupLight() {
        let ambientNode = SCNNode()
        ambientNode.light = SCNLight()
        ambientNode.light?.type = .ambient
        
        let directionalNode = SCNNode()
        directionalNode.light = SCNLight()
        directionalNode.light?.type = .directional
        directionalNode.light?.castsShadow = true
        directionalNode.light?.shadowColor = UIColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1)
        directionalNode.position = SCNVector3(x: -5, y: 5, z: 0)
        directionalNode.eulerAngles = SCNVector3(x: 0, y: -toRadians(angle: 90), z: -toRadians(angle: 45))
        
        lightNode.addChildNode(ambientNode)
        lightNode.addChildNode(directionalNode)
        lightNode.position = cameraNode.position
        scene.rootNode.addChildNode(lightNode)
    }
    
    func setupGestures() {
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeUp.direction = .up
        sceneView.addGestureRecognizer(swipeUp)
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeRight.direction = .right
        sceneView.addGestureRecognizer(swipeRight)
        
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeLeft.direction = .left
        sceneView.addGestureRecognizer(swipeLeft)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe))
        swipeDown.direction = .down
        sceneView.addGestureRecognizer(swipeDown)
    }

    func setupActions() {
        let moveUpAction = SCNAction.moveBy(x: 0, y: 1.0, z: 0, duration: 0.1)
        let moveDownAction = SCNAction.moveBy(x: 0, y: -1.0, z: 0, duration: 0.1)
        moveUpAction.timingMode = .easeOut
        moveDownAction.timingMode = .easeIn
        let jumpAction = SCNAction.sequence([moveUpAction, moveDownAction])
        
        let moveForwardAction = SCNAction.moveBy(x: 0, y: 0, z: -1.0, duration: 0.2) //right hand rule lol. Y is up and down via "height". X is left and right via the screen. Z is up and down via the screen.
        let moveRightAction = SCNAction.moveBy(x: 1.0, y: 0, z: 0, duration: 0.2)
        let moveLeftAction = SCNAction.moveBy(x: -1.0, y: 0, z: 0, duration: 0.2)
        let moveBackAction = SCNAction.moveBy(x: 0, y: 0, z: 1.0, duration: 0.2)
        
        let turnForwardAction = SCNAction.rotateTo(x: 0, y: toRadians(angle: 180), z: 0, duration: 0.2, usesShortestUnitArc: true)
        let turnRightAction = SCNAction.rotateTo(x: 0, y: toRadians(angle: 90), z: 0, duration: 0.2, usesShortestUnitArc: true)
        let turnLeftAction = SCNAction.rotateTo(x: 0, y: toRadians(angle: -90), z: 0, duration: 0.2, usesShortestUnitArc: true)
        let turnBackAction = SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.2, usesShortestUnitArc: true)
        
        jumpForwardAction = SCNAction.group([turnForwardAction, jumpAction, moveForwardAction])
        jumpRightAction = SCNAction.group([turnRightAction, jumpAction, moveRightAction])
        jumpLeftAction = SCNAction.group([turnLeftAction, jumpAction, moveLeftAction])
        jumpBackAction = SCNAction.group([turnBackAction, jumpAction, moveBackAction])
        
        driveRightAction = SCNAction.repeatForever(SCNAction.move(by: SCNVector3(x: 2.0, y: 0, z: 0), duration: 1.0))
        driveLeftAction = SCNAction.repeatForever(SCNAction.move(by: SCNVector3(x: -2.0, y: 0, z: 0), duration: 1.0))
        
        dieAction = SCNAction.repeat(SCNAction.rotate(by: .pi*2, around: SCNVector3(x: 0, y: 5, z: 0) ,duration: 0.2), count: 10)
        dieAction?.timingMode = .easeInEaseOut
    }
    
    func setupTraffic() {
        for lane in lanes {
            if let trafficNode = lane.trafficNode {
                addActions(for: trafficNode)
            }
        }
    }
    
    func jumpForward() {
        if let action = jumpForwardAction {
            addLanes()
            playerNode.runAction(action, completionHandler: {
                self.checkBlocks()
            })
        }
    }
    
    func jumpBack() {
        if let action = jumpBackAction {
            playerNode.runAction(action, completionHandler: {
                self.checkBlocks()
            })
        }
    }
    
    func updatePositions() {
        collisionNode.position = playerNode.position
        
        //our model moves in x and z directions only
        let diffX = (playerNode.position.x + 1 - cameraNode.position.x)
        let diffZ = (playerNode.position.z + 2 - cameraNode.position.z)
        //+1 and +2 to move the camera angled at the player instead of right above
        
        cameraNode.position.x += diffX
        cameraNode.position.z += diffZ
        
        lightNode.position = cameraNode.position
     
    }
    
    func updateTraffic() {
        for lane in lanes {
            guard let trafficNode = lane.trafficNode else {continue}
            for vehicle in trafficNode.childNodes {
                if vehicle.position.x > 10 {
                    vehicle.position.x = -10
                } else if vehicle.position.x < -10 {
                    vehicle.position.x = 10
                }
            }
        }
    }
    
    func addLanes() {
        //create two lanes. two since if you go forward, and the game is slightly tilted, you can see a bit of 2 lanes
        for _ in 0...1 {
            createNewLane(initial : false)
        }
        
        removeUnusedLanes()
    }
    
    func removeUnusedLanes() {
        for child in mapNode.childNodes {
            if !sceneView.isNode(child, insideFrustumOf: cameraNode) && child.worldPosition.z > playerNode.worldPosition.z {
                child.removeFromParentNode()
                lanes.removeFirst()
                score += 1
                gameHUD.pointsLabel?.text = String(score)
            }
        }
    }
    
    func createNewLane(initial: Bool) {
        let type = randomBool(odds: 3) || initial ? LaneType.grass : LaneType.road
        let lane = LaneNode(type: type, width: 21)
        lane.position = SCNVector3(x: 0, y: 0, z: 5 - Float(laneCount)) //z==5 is the first lane when you start the game at the bottom. its the initial distance.
        laneCount += 1
        lanes.append(lane)
        mapNode.addChildNode(lane)
        
        if let trafficNode = lane.trafficNode { //will not do anything at beginning since setupActions is after setupScene but thats why we added setupTraffic to implement this same functionality
            addActions(for: trafficNode)
        }
    }
    
    func addActions(for trafficNode: TrafficNode) {
        guard let driveAction = trafficNode.directionRight ? driveRightAction : driveLeftAction else {return}
        driveAction.speed = 1/CGFloat(trafficNode.type + 1) + 0.5 //our types range from 0 - 2. +0.5 makes the speed a bit faster
        for vehicle in trafficNode.childNodes {
            vehicle.removeAllActions()
            vehicle.runAction(driveAction)
        }
    }
    
    func gameOver() {
        DispatchQueue.main.async {
            if let gestureRecognizers = self.sceneView.gestureRecognizers {
                for recognizer in gestureRecognizers {
                    self.sceneView.removeGestureRecognizer(recognizer)
                }
            }
        }
        gameState = .gameOver
        if let action = dieAction {
            playerNode.runAction(action) {
                self.resetGame()
            }
        }
    }
}

extension GameViewController : SCNSceneRendererDelegate { //this is constantly called since its the renderer
    
    func renderer(_ renderer: SCNSceneRenderer, didApplyAnimationsAtTime time: TimeInterval) {
        updatePositions()
        updateTraffic()
    }
}

extension GameViewController : SCNPhysicsContactDelegate {
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        guard let categoryA = contact.nodeA.physicsBody?.categoryBitMask, let categoryB = contact.nodeB.physicsBody?.categoryBitMask else {return}
        
        let mask = categoryA | categoryB
        
        switch mask {
        case PhysicsCategories.chicken | PhysicsCategories.vehicle:
            gameOver()
        case PhysicsCategories.vegetation | PhysicsCategories.collisionTestFront:
            frontBlocked = true
        case PhysicsCategories.vegetation | PhysicsCategories.collisionTestRight:
            rightBlocked = true
        case PhysicsCategories.vegetation | PhysicsCategories.collisionTestLeft:
            leftBlocked = true
        case PhysicsCategories.vegetation | PhysicsCategories.collisionTestBack:
            backBlocked = true
        default:
            break
        }
    }
}

extension GameViewController {
    
    @objc func handleSwipe(_ sender: UISwipeGestureRecognizer) {
        
        switch sender.direction {
        case UISwipeGestureRecognizerDirection.up:
            if !frontBlocked {
                jumpForward()
            }
        case UISwipeGestureRecognizerDirection.right:
            if playerNode.position.x < 10 && !rightBlocked {
                if let action = jumpRightAction {
                    playerNode.runAction(action, completionHandler: {
                        self.checkBlocks()
                    })
                }
            }
        case UISwipeGestureRecognizerDirection.left:
            if playerNode.position.x > -10 && !leftBlocked{
                if let action = jumpLeftAction {
                    playerNode.runAction(action, completionHandler: {
                        self.checkBlocks()
                    })
                }
            }
        case UISwipeGestureRecognizerDirection.down:
            if playerNode.position.z < mapNode.childNodes.first!.worldPosition.z && !backBlocked{
                jumpBack()
            }
        default:
            break
        }
    }
    
    func checkBlocks() {
        if scene.physicsWorld.contactTest(with: collisionNode.front.physicsBody!, options: nil).isEmpty {
            frontBlocked = false
        }
        
        if scene.physicsWorld.contactTest(with: collisionNode.right.physicsBody!, options: nil).isEmpty {
            rightBlocked = false
        }
        
        if scene.physicsWorld.contactTest(with: collisionNode.left.physicsBody!, options: nil).isEmpty {
            leftBlocked = false
        }
        
        if scene.physicsWorld.contactTest(with: collisionNode.back.physicsBody!, options: nil).isEmpty {
            backBlocked = false
        }
    }
}
