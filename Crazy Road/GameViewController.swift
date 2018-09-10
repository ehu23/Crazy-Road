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

class GameViewController: UIViewController {

    var scene: SCNScene!
    var sceneView: SCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScene()
    }
    
    
    func setupScene() {
        sceneView = view as! SCNView
        scene = SCNScene()
        
        sceneView.scene = scene
    }
}
