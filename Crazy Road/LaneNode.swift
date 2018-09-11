//
//  LaneNode.swift
//  Crazy Road
//
//  Created by Edward Hu on 9/10/18.
//  Copyright © 2018 Edward Hu. All rights reserved.
//

import SceneKit

enum LaneType {
    case grass,road
}

class LaneNode: SCNNode {

    let type: LaneType
    
    init(type: LaneType, width: CGFloat) {
        
        self.type = type
        super.init()
        
        switch type {
        case .grass:
            guard let texture = UIImage(named: "art.scnassets/grass.png") else {break}
            createLane(width: width, height: 0.4, image: texture)
        case .road:
            guard let texture = UIImage(named: "art.scnassets/asphalt.png") else {break}
            createLane(width: width, height: 0.05, image: texture)
        }
    }
    
    func createLane(width: CGFloat, height: CGFloat, image: UIImage) {
        let laneGeometry = SCNBox(width: width, height: height, length: 1, chamferRadius: 0) //chamferRadius is how round the corners of the box are
        laneGeometry.firstMaterial?.diffuse.contents = image
        laneGeometry.firstMaterial?.diffuse.wrapT = .repeat
        laneGeometry.firstMaterial?.diffuse.wrapS = .repeat
        laneGeometry.firstMaterial?.diffuse.contentsTransform = SCNMatrix4MakeScale(Float(width), 1, 1)
        
        let laneNode = SCNNode(geometry: laneGeometry)
        addChildNode(laneNode)
        addElements(width, laneNode)
    }
    
    func addElements(_ width: CGFloat, _ laneNode: SCNNode) {
        for index in 0..<Int(width) {
            if type == .grass {
                if randomBool(odds: 7) {
                    let vegetation = getVegetation()
                    vegetation.position = SCNVector3(x: 10 - Float(index), y: 0, z: 0) //since 10 is the rightmost column
                    laneNode.addChildNode(vegetation)
                }
            } else if type == .road {
                
            }
        }
    }
    
    func getVegetation() -> SCNNode{
        let vegetation = randomBool(odds: 2) ? Models.tree.clone() : Models.hedge.clone()
        return vegetation
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
