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

enum BlockType {
    case grow
    case recurse
    case leaf
}

protocol Block {
    var type: BlockType! { get set }
    var node: SCNNode!  { get set }
    var position: SCNVector3! { get }
    var transform: SCNMatrix4! { get }
    var rotation: SCNVector4! { get }
    var eulerAngles: SCNVector3! { get }
}

protocol Detectable {
    var anchor: ARImageAnchor! { get set }
    var id: String! { get }
}

protocol Recursable {
    var parent: Block! { get set }
}

class PhysicalBlock: Block, Detectable {
    var type: BlockType!
    var node: SCNNode!
    var anchor: ARImageAnchor!
    var position: SCNVector3! {
        return self.node.position
    }
    var transform: SCNMatrix4! {
        return self.node.transform
    }
    var rotation: SCNVector4! {
        return self.node.rotation
    }
    var eulerAngles: SCNVector3! {
        return self.node.eulerAngles
    }
    var id: String! {
        return self.anchor.name!
    }
    
    
    init(type: BlockType, node: SCNNode, anchor: ARImageAnchor) {
        self.type = type
        self.anchor = anchor
        self.node = node
    }
    
    func update(node: SCNNode, anchor: ARImageAnchor) {
        self.node = node
        self.anchor = anchor
    }
}

class VirtualBlock: Block, Recursable {
    var parent: Block!
    var type: BlockType!
    var node: SCNNode!
    var position: SCNVector3! {
        return self.node.position
    }
    var transform: SCNMatrix4! {
        return self.node.transform
    }
    var rotation: SCNVector4! {
        return self.node.rotation
    }
    var eulerAngles: SCNVector3! {
        return self.node.eulerAngles
    }
}

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    // A serial queue for thread safety when modifying SceneKit's scene graph.
    let updateQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).serialSCNQueue")
    
    // MARK: - Visual content pre-defined blocks
    var physicalBlocks: [String: PhysicalBlock]!
    var virtualBlocks: [String: VirtualBlock]!
    var connectors = [String: Connector]()
    
    var testNode: SCNNode!
    var testNode2: SCNNode!


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
        
        
        
        // Initialize the physical blocks
//        physicalBlocks = [growBlock?.id : growBlock,
//                          recurseBlock?.id: recurseBlock,
//                          leaf1Block?.id : leaf1Block,
//                          leaf2Block?.id: leaf2Block]
        
        // Initialize physical blocks
        physicalBlocks = [String: PhysicalBlock]()
        
        let geo = SCNSphere(radius: 0.0075)
        geo.firstMaterial?.diffuse.contents = UIColor.red
        testNode = SCNNode(geometry: geo)
        testNode2 = SCNNode(geometry: geo)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        guard let refImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: Bundle.main) else {
            fatalError("Missing expected asset catalog resources.")
        }
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()
        configuration.trackingImages = refImages
        configuration.maximumNumberOfTrackedImages = 4
        
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
    
    // MARK: - Visual processing
    func updateView() {
        
        // Make sure you get the curse block to refer to
        guard let recurseBlock = physicalBlocks["RECURSE"] else { return }
        
        // Update the positions of the connectors
        for (id, conn) in connectors {
            conn.update(startPos: physicalBlocks[id]!.position, endPos: recurseBlock.position)
        }
        
        // Don't continue until you have the grow to reference
        guard let growBlock = physicalBlocks["GROW"] else { return }
        
        // Make it general so that it looks for ANY leaf
        // And if it does, to look for the other one
        
        guard let leaf1 = physicalBlocks["LEAF_1"] else { return }
        guard let leaf2 = physicalBlocks["LEAF_2"] else { return }
        
        
        let angle1 = getAngle(v1: growBlock.position, v2: recurseBlock.position, v3: leaf1.position, degrees: false)
        let angle2 = getAngle(v1: growBlock.position, v2: recurseBlock.position, v3: leaf2.position, degrees: false)

        let leaf1Offset = leaf1.position - recurseBlock.position
        let leaf2Offset = leaf2.position - recurseBlock.position
        
        updateQueue.async {
            
            leaf1.node.addChildNode(self.testNode)
            leaf1.node.addChildNode(self.testNode2)

            // Convert two parent's up: the last reference
            let leaf1Trans = self.testNode.convertVector(leaf1Offset, from: self.testNode.parent!.parent)
            let leaf2Trans = self.testNode2.convertVector(leaf2Offset, from: self.testNode2.parent!.parent)

            
            self.testNode.position = leaf1Trans
            self.testNode.rotation = self.testNode.parent!.rotation
            self.testNode.rotation.y *= -1
            
            self.testNode2.position = leaf2Trans
            self.testNode2.rotation = self.testNode2.parent!.rotation
            self.testNode2.rotation.y *= -1
        }
    }
//
//            let angle = getAngle(v1: growBlock.position, v2: recurseBlock.position, v3: leaf2.position, degrees: false)
//
//            // Figure out how to get node look at rotation
//            let offsetVector: SCNVector3 = recurseBlock.position - growBlock.position
//
//            let leafOffset = leaf2.position - recurseBlock.position
//            let translationVector = SCNVector3(0, offsetVector.y, 0)
//
//            updateQueue.async {
//
//                leaf2.node.addChildNode(self.testNode2)
//                // Convert two parent's up: the last reference
//                let adjustedTranslation = self.testNode2.convertVector(leafOffset, from: self.testNode2.parent!.parent)
//
//                self.testNode2.position = adjustedTranslation
//                self.testNode2.rotation = self.testNode2.parent!.rotation
//                self.testNode2.rotation.y *= -1
//            }
//        }
    
        // Now, for the recursive part
        // Dummy version:
        /*
         
         for each level of depth
         look at the base structure and angles
         copy all of its relative positions
         
         translate and rotate by the leaf/grow ratio * the level of depth
         
         */
        
//    }
    
    func getAngle(v1: SCNVector3, v2: SCNVector3, v3: SCNVector3, degrees: Bool) -> Float {
        let a = pow(v2.x - v1.x,2) + pow(v2.y-v1.y,2) + pow(v2.z-v1.z,2)
        let b = pow(v2.x-v3.x,2) + pow(v2.y-v3.y,2) + pow(v2.z-v3.z,2)
        let c = pow(v3.x-v1.x,2) + pow(v3.y-v1.y,2) + pow(v3.z-v1.z,2)
        
        var division: Float
        if degrees {
            division = 360 / (2 * Float.pi)
        } else {
            division = 1
        }
        return (acos( (a+b-c) / sqrt(4*a*b))) * Float(division)
    }

    
    // MARK: - ARSCNViewDelegate
    
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        // Make sure the image  anchor exists
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        guard let block =  physicalBlocks[imageAnchor.name!] else { return }
        
        // Update the block
        block.update(node: node, anchor: imageAnchor)
        
        // Parse the input
        updateView()
    }
    
    
    // Adds the marker nodes to the scene.
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        // Delegate rendering tasks to our `updateQueue` thread to keep things thread-safe!
        updateQueue.async {
            
            guard let imageAnchor = anchor as? ARImageAnchor else { return }
            
            let id = imageAnchor.name!
            let type: BlockType!
            
            // Abstract this into Block, so that it parses the image anchor name automatically
            if id.contains("GROW"){
                type = .grow
            } else if id.contains("RECURSE") {
                type = .recurse
            } else {
                type = .leaf
            }
            
            print("DETECTED: \(id)")
            
            // Add the block
            let block = PhysicalBlock(type: type, node: node, anchor: imageAnchor)
            self.physicalBlocks[id] = block

            let physicalWidth = imageAnchor.referenceImage.physicalSize.width
            let physicalHeight = imageAnchor.referenceImage.physicalSize.height
            
            // Create a plane geometry to visualize the initial position of the detected image
            let mainPlane = SCNPlane(width: physicalWidth, height: physicalHeight)
            var color: UIColor!
            
            if imageAnchor.name!.contains("GROW") {
                color = UIColor.brown
            } else if imageAnchor.name!.contains("LEAF") {
                color = UIColor.green
            } else {
                color = UIColor.blue
            }
            
            if type != .recurse {
                let connector = Connector(positionStart: block.position, positionEnd: SCNVector3Zero, radius: 0.001, color: UIColor.white)
                connector.to = block
                self.connectors[id] = connector
                self.sceneView.scene.rootNode.addChildNode(connector)
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
            sphereNode.opacity = 0.25
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
