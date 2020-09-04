//
//  ViewController.swift
//  ARMeasuring
//
//  Created by Benjamin Salter on 8/30/20.
//  Copyright © 2020 Benjamin Salter. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var distance: UILabel!
    @IBOutlet weak var xLabel: UILabel!
    @IBOutlet weak var yLabel: UILabel!
    @IBOutlet weak var zLabel: UILabel!
    var startingPosition: SCNNode?
    let configuration = ARWorldTrackingConfiguration()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.sceneView.debugOptions = [ARSCNDebugOptions.showWorldOrigin, ARSCNDebugOptions.showFeaturePoints]
        self.sceneView.session.run(configuration)
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        self.sceneView.addGestureRecognizer(tapGestureRecognizer)
        sceneView.delegate = self
    }
    
    @objc func handleTap(sender: UITapGestureRecognizer) {
        guard let sceneView = sender.view as? ARSCNView else { return }
        guard let currentFrame = sceneView.session.currentFrame else { return }
        if startingPosition != nil {
            startingPosition?.removeFromParentNode()
            startingPosition = nil
        }
        let camera = currentFrame.camera
        let transform = camera.transform
        var translationMatrix = matrix_identity_float4x4
        translationMatrix.columns.3.z = -0.1 // adjust the starting position slightly back from camera
        let modifiedMatrix = simd_mul(transform, translationMatrix)
        let sphere = SCNNode(geometry: SCNSphere(radius: 0.005))
        sphere.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
        sphere.simdTransform = modifiedMatrix // positions node in front of camera
        sceneView.scene.rootNode.addChildNode(sphere)
        startingPosition = sphere
    }
}

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        guard let startingPosition = self.startingPosition else { return }
        guard let pointOfView = sceneView.pointOfView else { return }
        let transform = pointOfView.transform
        let location = SCNVector3(x: transform.m41, y: transform.m42, z: transform.m43)
        let xDistance = location.x - startingPosition.position.x
        let yDistance = location.y - startingPosition.position.y
        let zDistance = location.z - startingPosition.position.z
        DispatchQueue.main.async {
            self.xLabel.text = "length: " + String(format: "%.2f", xDistance) + "m"
            self.yLabel.text = "height: " + String(format: "%.2f", yDistance) + "m"
            self.zLabel.text = "depth: " + String(format: "%.2f", zDistance) + "m"
            self.distance.text = "distance: " + String(format: "%.2f", distanceTravelled(x: xDistance, y: yDistance, z: zDistance)) + "m"
        }
    }
}

func distanceTravelled(x: Float, y: Float, z: Float) -> Float {
    return (sqrtf(x*x + y*y + z*z))
}
