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
    
    // MARK: - Visual stuff
    var blocks = [String: Block]()
    var connectors = [String: Connector]()
    
    // Keeps references between blocks
    var connections = [String:String]()
    
    // MARK: - User parameters
    // Level of recursion
    var depthLevel: Int = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        sceneView.session.delegate = self
        sceneView.debugOptions = [.showCameras ,.showBoundingBoxes, .showWorldOrigin, .showConstraints]
        
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
    }
    
    // Function for parsing the visual input
    // actually no this needs to be recursive
    func parseAnchors() {
        for (name, block) in blocks {
            
            // If this was already connected to, skip. This avoids duplicate connections
            if connections.values.contains(name) {
                continue
            }
            
            // only go on if the block actually has something next to it
            guard  let next = findNext(from: block) else { continue }
            
            // Update the connections based on the block positions
            connections[name] = next.id
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
    
    func renderPlant() {
        // given blocks and connections
        // you dont need the angles?
        // draw lines between them!
        for (from, to) in connections {
            
            guard let fb = blocks[from] else { return }
            guard let tb = blocks[to] else { return }
            guard let conn = connectors[from] else { return }
            
            fb.node.look(at: tb.position)
            conn.update(startPos: fb.position, endPos: tb.position)
        }
    }
    
    // Recursively duplicates the given blocks/connections
    // Pass down the size?
    func recurse(depth: Int) {
        // Recurse down until depth is 1
        if(depth == 1) {
            return
        } else {
            recurse(depth: depth-1)
        }
    }
    
    // MARK: - ARSCNViewDelegate
    
//     Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Make sure the image  anchor exists
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        
        // Update the block
        blocks[imageAnchor.name!]?.update(node: node, anchor: imageAnchor)
        
        // Reparse and rerender
        parseAnchors()
        renderPlant()
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
        
        // Add the block
        let block = Block(type: type, node: node, anchor: imageAnchor)
        blocks[imageAnchor.name!] = block
        
        // Initialize an edge
        let connector = Connector(positionStart: block.position, positionEnd: SCNVector3Zero, radius: 0.0075, color: UIColor.yellow)
        connectors[imageAnchor.name!] = connector
        self.sceneView.scene.rootNode.addChildNode(connector)
        
        // Delegate rendering tasks to our `updateQueue` thread to keep things thread-safe!
        updateQueue.async {

            let physicalWidth = imageAnchor.referenceImage.physicalSize.width
            let physicalHeight = imageAnchor.referenceImage.physicalSize.height
            
            // Create a plane geometry to visualize the initial position of the detected image
            let mainPlane = SCNPlane(width: physicalWidth, height: physicalHeight)
            var color: UIColor!
            
            switch(imageAnchor.name) {
            case "GROW":
                color = UIColor.brown
                break
            case "LEAF":
                color = UIColor.green
                break
            case "REPEAT":
                color = UIColor.blue
                break
            default:
                color = UIColor.white
                return
            }
            
            // Assign the color
            mainPlane.firstMaterial?.diffuse.contents = color
            
            // Create a SceneKit root node with the plane geometry to attach to the scene graph
            // This node will hold the virtual UI in place
            //  x reference
            let xReferenceNode = SCNNode(geometry: mainPlane)
            xReferenceNode.eulerAngles.x = -.pi
            xReferenceNode.renderingOrder = -1
            xReferenceNode.opacity = 0.5
            
            // This is the marker
            let markerNode = SCNNode(geometry: mainPlane)
            markerNode.eulerAngles.x = -.pi/2
            markerNode.renderingOrder = 0
            markerNode.opacity = 0.25
            
            let sphereNode = SCNNode(geometry: SCNSphere(radius: 0.015))
            sphereNode.renderingOrder = 1
            
            // Add the plane visualization to the scene
            node.addChildNode(xReferenceNode)
            node.addChildNode(markerNode)
            node.addChildNode(sphereNode)
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
