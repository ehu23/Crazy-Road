//
//  CollisionNode.swift
//  Crazy Road
//
//  Created by Edward Hu on 9/10/18.
//  Copyright © 2018 Edward Hu. All rights reserved.
//

import SceneKit

class CollisionNode: SCNNode {

    let front: SCNNode
    let right: SCNNode
    let left: SCNNode
    let back: SCNNode
    
    override init() {
        front = SCNNode()
        right = SCNNode()
        left = SCNNode()
        back = SCNNode()
        
        super.init()
        createPhysicsBodies()
    }
    
    func createPhysicsBodies() {
        let boxGeometry = SCNBox(width: 0.25, height: 0.25, length: 0.25, chamferRadius: 0)
        boxGeometry.firstMaterial?.diffuse.contents = UIColor.clear
        
        let shape = SCNPhysicsShape(geometry: boxGeometry, options: [SCNPhysicsShape.Option.type : SCNPhysicsShape.ShapeType.boundingBox])
        
        front.geometry = boxGeometry
        right.geometry = boxGeometry
        left.geometry = boxGeometry
        back.geometry = boxGeometry
        
        front.physicsBody = SCNPhysicsBody(type: .kinematic, shape: shape)
        front.physicsBody?.categoryBitMask = PhysicsCategories.collisionTestFront
        front.physicsBody?.contactTestBitMask = PhysicsCategories.vegetation
        
        right.physicsBody = SCNPhysicsBody(type: .kinematic, shape: shape)
        right.physicsBody?.categoryBitMask = PhysicsCategories.collisionTestRight
        right.physicsBody?.contactTestBitMask = PhysicsCategories.vegetation
        
        left.physicsBody = SCNPhysicsBody(type: .kinematic, shape: shape)
        left.physicsBody?.categoryBitMask = PhysicsCategories.collisionTestLeft
        left.physicsBody?.contactTestBitMask = PhysicsCategories.vegetation
        
        back.physicsBody = SCNPhysicsBody(type: .kinematic, shape: shape)
        back.physicsBody?.categoryBitMask = PhysicsCategories.collisionTestBack
        back.physicsBody?.contactTestBitMask = PhysicsCategories.vegetation
        
        front.position = SCNVector3(x: 0, y: 0.5, z: -1)   //0.5 to move it up a little
        right.position = SCNVector3(x: 1, y: 0.5, z: 0)
        left.position = SCNVector3(x: -1, y: 0.5, z: 0)
        back.position = SCNVector3(x: 0, y: 0.5, z: 1)
        
        addChildNode(front)
        addChildNode(right)
        addChildNode(left)
        addChildNode(back)
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
