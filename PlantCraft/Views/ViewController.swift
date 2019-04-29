//
//  ViewController.swift
//  PlantCraft
//
//  Created by Tyler Angert on 4/27/19.
//  Copyright © 2019 Tyler Angert. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    // A serial queue for thread safety when modifying SceneKit's scene graph.
    let updateQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).serialSCNQueue")
    
    // MARK - Visual stuff
    var blocks = [String: Block]()
    var connectors = [String: Connector]()
    
    // Keeps referneces between blocks and connectors
    var connections = [String:String]()

//    var cyl = SCNNode()
    
    // Have to store the tree of images/commands
    // Maybe have a distance threshold for checking?
    
    // Figure out drawing the cylinders and updating their positions.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        
        sceneView.session.delegate = self
        
        // Set the scene to the view
        sceneView.scene = scene
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let refImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: Bundle.main) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()
        configuration.trackingImages = refImages
        configuration.maximumNumberOfTrackedImages = 20
        
        // Run the view's session
        sceneView.session.run(configuration, options: ARSession.RunOptions(arrayLiteral: [.resetTracking, .removeExistingAnchors]))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - ARSessionDelegate
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        parseAnchors()
    }
    
    // Function for parsing the visual input
    // actually no this needs to be recursive
    func parseAnchors() {
        for (name, block) in blocks {
            // If this was already connected to
            if connections.values.contains(name) {
                continue
            }
            guard  let next = findNext(from: block) else { continue }
            connections[name] = next.id
            connectors[block.id]!.update(startPos: block.position, endPos: next.position)
        }
        
    }
    
    // Figure out this function. Finding the next block.
    func findNext(from: Block) -> Block? {
        
        var next: Block?
        var minDist = Float.greatestFiniteMagnitude

        for (name, block) in blocks where name != from.id! {
            
            // minimum distance given the direction/orientation of the anchor
            let dist = (from.position - block.position).magnitude
            
            // Assign the new next block
            if dist < minDist {
                minDist = dist
                next = block
            }
            
        }
        return next
    }

    // MARK: - ARSCNViewDelegate
//     Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        
        // Abstract this into an update function
        blocks[imageAnchor.name!]?.anchor = imageAnchor
        blocks[imageAnchor.name!]?.rotation = node.eulerAngles

    }
    
    
    // Adds the marker nodes to the scene.
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        
        let type: BlockType!
        
        if imageAnchor.name! == "GROW" {
            type = BlockType.grow
        } else if imageAnchor.name! == "REPEAT" {
            type = BlockType.recurse
        } else {
            type = BlockType.leaf
        }
        
        let block = Block(type: type, node: node, anchor: imageAnchor)
        blocks[imageAnchor.name!] = block
        
        // Initialize an edge
        let connector = Connector(positionStart: block.position, positionEnd: SCNVector3Zero, radius: 0.01, color: UIColor.yellow)
        connectors[imageAnchor.name!] = connector

        self.sceneView.scene.rootNode.addChildNode(connector)

        print("orientation \(node.orientation)")
        print("rotation \(node.rotation)")
        print("euler angles \(node.eulerAngles)")
        
        // Delegate rendering tasks to our `updateQueue` thread to keep things thread-safe!
        updateQueue.async {
 
            
            let physicalWidth = imageAnchor.referenceImage.physicalSize.width
            let physicalHeight = imageAnchor.referenceImage.physicalSize.height
            
            // This bit is important. It helps us create occlusion so virtual things stay hidden behind the detected image
            // mainPlane.firstMaterial?.colorBufferWriteMask = .alpha
            
            // Create a plane geometry to visualize the initial position of the detected image
            let mainPlane = SCNPlane(width: physicalWidth, height: physicalHeight)
            var color: UIColor!
            
            switch(imageAnchor.name) {
            case "GROW":
                color = UIColor.green
                break
            case "LEAF":
                color = UIColor.red
                break
            case "REPEAT":
                color = UIColor.blue
                break
            default:
                color = UIColor.white
                return
            }
            
            // Create a SceneKit root node with the plane geometry to attach to the scene graph
            // This node will hold the virtual UI in place
            let mainNode = SCNNode(geometry: mainPlane)
            mainNode.eulerAngles.x = -.pi / 2
            mainNode.renderingOrder = -1
            mainNode.opacity = 1
            mainPlane.firstMaterial?.diffuse.contents = color
            
            // Add the plane visualization to the scene
            node.addChildNode(mainNode)
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

extension matrix_float4x4 {
    func position() -> SCNVector3 {
        return SCNVector3(self.columns.3.x, self.columns.3.y, self.columns.3.z)
    }
}

extension ARImageAnchor {
    var position: SCNVector3 {
        get {
            return SCNVector3(self.transform.columns.3.x, self.transform.columns.3.y, self.transform.columns.3.z)
        }
    }
    
//    var rotation: (Float,Float,Float) {
//        get {
//            return (0,0,0)
//        }
//    }
}
