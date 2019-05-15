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
    
    // MARK: - Visual content pre-defined blocks
    var physicalBlocks = [String: PhysicalBlock]()
    var virtualBlocks = [String: VirtualBlock]()
    
    var physicalConnectors = [String: Connector]()
    var virtualConnectors = [String: Connector]()

    // MARK: - User parameters
    // Level of recursion
    var currentDepth: Int = 1
    var maxDepth: Int = 6
    var currentRecurseRotation = SCNVector3()
    let threshold: CGFloat = (.pi*2) / 6
    let rotationOffset: CGFloat = .pi
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene()
        sceneView.session.delegate = self
        sceneView.debugOptions = [.showWorldOrigin, .showConstraints]
        
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
        
        // Update the depth level
        let currentRotation = CGFloat(recurseBlock.eulerAngles.z - Float(rotationOffset))
        currentDepth = -(Int(currentRotation / threshold) - 1)
        
//        let dummy
//        let orientation = recurseBlock.node.orientation
//        var glQuaternion = GLKQuaternionMake(orientation.x, orientation.y, orientation.z, orientation.w)
//
        // Rotate around Z axis
//        let multiplier = GLKQuaternionMakeWithAngleAndAxis(0.5, 0, 0, 1)
//        glQuaternion = GLKQuaternionMultiply(glQuaternion, multiplier)
        
//        print(recurseBlock.node.orientation)
//        print(recurseBlock.node.pivot)

        
//        print(recurseBlock.eulerAngles.z)
//        print(recurseBlock.node.orientation)
        
//        guard let recurseWolrdNode =  sceneView.node(for: recurseBlock.anchor) else { return }
//
//        let convertedTransform = recurseBlock.node.convertVector(recurseBlock.eulerAngles, to: sceneView)
        
//        let anchorNodeOrientation = recurseWolrdNode.worldOrientation

//        print(currentRecurseRotation)
        

        // Update the positions of the connectors
        for (id, conn) in physicalConnectors {
            conn.update(startPos: physicalBlocks[id]!.position, endPos: recurseBlock.position)
        }
        
        // Don't continue until you have the grow to reference
        guard let growBlock = physicalBlocks["GROW"] else { return }
        
        // Make it general so that it looks for ANY leaf
        // And if it does, to look for the other one
        guard let leaf1 = physicalBlocks["LEAF_1"] else { return }
        guard let leaf2 = physicalBlocks["LEAF_2"] else { return }
        
        let leaf1Offset = leaf1.position - recurseBlock.position
        let leaf2Offset = leaf2.position - recurseBlock.position

        DispatchQueue.main.async {
            // Update the recurse block's text
            let text = recurseBlock.node.childNode(withName: "DEPTH_LABEL", recursively: false)?.geometry as! SCNText
            text.string = "\(self.currentDepth)"
            
            // Iterative updates
            self.updateVirtualBlocks(depth: self.currentDepth, offset1: leaf1Offset, offset2: leaf2Offset)
            
            // Recursive updates
            //self.recursivelyUpdate(from: leaf1, depth: self.currentDepth, offset1: leaf1Offset, offset2: leaf2Offset)
            //self.recursivelyUpdate(from: leaf2, depth: self.currentDepth, offset1: leaf1Offset, offset2: leaf2Offset)

        }
    }
    
    func updateVirtualBlocks(depth: Int, offset1: SCNVector3, offset2: SCNVector3) {
//        for(_, conn) in virtualConnectors {
//            if conn.depth <= currentDepth {
//                conn.opacity = 1
//            } else {
//                conn.opacity = 0
//            }
//
//            let block = conn.startBlock!
//
//            if block.childBlocks.count > 0 {
//                let child1 = block.childBlocks[0].node!
//                let child2 = block.childBlocks[1].node!
//
//                let from1Trans = child1.convertVector(offset1, from: child1.parent!.parent)
//                let from2Trans = child2.convertVector(offset2, from: child2.parent!.parent)
//
//                // Adjust the scale out on every level
//                let scaleFactor = powf(0.8, Float(depth))
//
//                child1.position = from1Trans * scaleFactor
//                child1.rotation = child1.parent!.rotation
//
//                child2.position = from2Trans * scaleFactor
//                child2.rotation = child2.parent!.rotation
//
//                conn.update(startPos: block.position, endPos: <#T##SCNVector3#>)
//                block.connector1.update(startPos: block.position, endPos: child1.position)
//                block.connector2.update(startPos: block.position, endPos: child2.position)
//            }
//        }
//
        for (_, block) in virtualBlocks {
            
            if block.depth <= currentDepth {
                block.node.opacity = 1
            } else {
                block.node.opacity = 0
            }
            
            if block.childBlocks.count > 0 {
                let child1 = block.childBlocks[0].node!
                let child2 = block.childBlocks[1].node!
                
                let from1Trans = child1.convertVector(offset1, from: child1.parent!.parent)
                let from2Trans = child2.convertVector(offset2, from: child2.parent!.parent)
                
                // Adjust the scale out on every level
                let scaleFactor = powf(0.8, Float(depth))
                
                child1.position = from1Trans * scaleFactor
                child1.rotation = child1.parent!.rotation
                
                child2.position = from2Trans * scaleFactor
                child2.rotation = child2.parent!.rotation
                
                let connector1Id = "\(String(describing: block.id!))-\(String(describing: block.childBlocks[0].id))"
                let connector2Id = "\(String(describing: block.id!))-\(String(describing: block.childBlocks[1].id))"
                
                virtualConnectors[connector1Id]?.update(startPos: block.position, endPos: child1.position)
                virtualConnectors[connector2Id]?.update(startPos: block.position, endPos: child1.position)

//                block.connector1.update(startPos: block.position, endPos: child1.position)
//                block.connector2.update(startPos: block.position, endPos: child2.position)
//                virtualConnectors[children[0].name!]!.update(startPos: block.position, endPos: children[0].position)
//                virtualConnectors[children[1].name!]!.update(startPos: block.position, endPos: children[1].position)
            }
        }
    }
//
//    func recursivelyUpdate(from: Block, depth: Int, offset1: SCNVector3, offset2: SCNVector3) {
//        if depth == 1 {
//            // BASIC: Adjust opacity
//            // TODO: Scale/grow
//            if from.depth <= currentDepth {
//                from.node.opacity = 1
//            } else {
//                from.node.opacity = 0
//            }
//            return
//        } else {
//            // Convert two parent's up: the last reference
//            guard let children = from.childBlocks else { return }
//            let child1Node = children[0].node!
//            let child2Node = children[1].node!
//
//            let from1Trans = child1Node.convertVector(offset1, from: child1Node.parent!.parent)
//            let from2Trans = child2Node.convertVector(offset2, from: child2Node.parent!.parent)
//
//            // Adjust by parameter
//            let translationScale: SCNFloat = 0.67 * Float(from.depth)
//
//            // implement rotation scale
//            let rotationScale: SCNFloat = 1
//
//            child1Node.position = from1Trans * translationScale
//            child1Node.rotation = child1Node.parent!.rotation
//            child1Node.rotation.y *= -1
//
//            child2Node.position = from2Trans
//            child2Node.rotation = child2Node.parent!.rotation
//            child2Node.rotation.y *= -1
//
//            recursivelyUpdate(from: children[0], depth: depth-1, offset1: from1Trans, offset2: from2Trans)
//            recursivelyUpdate(from: children[1], depth: depth-1, offset1: from1Trans, offset2: from2Trans)
//        }
//    }
//
    // MARK: - ARSCNViewDelegate
    
    // Updates the nodes
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
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
            
            // Add the block
            let block = PhysicalBlock(type: type, node: node, anchor: imageAnchor)
            block.depth = 1
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
                connector.startBlock = block
                self.physicalConnectors[id] = connector
                self.sceneView.scene.rootNode.addChildNode(connector)
            }
            
            // Assign the color
            mainPlane.firstMaterial?.diffuse.contents = color
            
            
            if type == .recurse {
                
                // This node will hold the virtual UI in place
                mainPlane.cornerRadius = mainPlane.width/2
                let repeatUI = SCNNode(geometry: mainPlane)
                repeatUI.name = "REPEAT_UI"
                repeatUI.eulerAngles.x = -.pi/2
                repeatUI.geometry?.firstMaterial?.isDoubleSided = true
                repeatUI.renderingOrder = -2
                repeatUI.opacity = 1.0
                
                // Holds the current depth level
                let textGeometry = SCNText(string: "\(self.currentDepth)", extrusionDepth: 0.1)
                textGeometry.font = UIFont.systemFont(ofSize: 1.0)
                textGeometry.flatness = 0.0025
                textGeometry.firstMaterial?.diffuse.contents = UIColor.white
                let fontSize = Float(0.02)

                let textNode = SCNNode(geometry: textGeometry)
                textNode.renderingOrder = -3
                textNode.scale = SCNVector3(fontSize, fontSize, fontSize)
                textNode.eulerAngles.x = -.pi/2
                textNode.name = "DEPTH_LABEL"
                
                // Acts as a dial marker
                let depthMarker = SCNNode(geometry: SCNSphere(radius: 0.005))

                // depthMarker.localTranslate(by: SCNVector3(-20,0,0))
                
                node.addChildNode(textNode)
                node.addChildNode(repeatUI)
                node.addChildNode(depthMarker)
                
            } else {
                
                // Create a SceneKit root node with the plane geometry to attach to the scene graph
                // This node will hold the virtual UI in place
                let xReferenceNode = SCNNode(geometry: mainPlane)
                xReferenceNode.eulerAngles.x = -.pi
                xReferenceNode.renderingOrder = -1
                xReferenceNode.opacity = 0.5
                
                // This is the marker
                let markerNode = SCNNode(geometry: mainPlane)
                markerNode.eulerAngles.x = -.pi/2
                markerNode.renderingOrder = 0
                markerNode.opacity = 0.25
                
                let sphereNode = SCNNode(geometry: SCNSphere(radius: 0.010))
                sphereNode.opacity = 0.25
                sphereNode.renderingOrder = 1
                
                // Add the plane visualization to the scene
                node.addChildNode(xReferenceNode)
                node.addChildNode(markerNode)
                node.addChildNode(sphereNode)
            }
            
            self.sceneView.scene.rootNode.addChildNode(node)
            
            // NOW, THE MOMENT ALL FOUR ARE RECOGNIZED, YOU PREPOPULATE!!!
            if self.physicalBlocks.count == 4 && self.virtualBlocks.isEmpty {
                
                // Pre populate all of the nodes
                guard let leaf1 = self.physicalBlocks["LEAF_1"] else { return }
                guard let leaf2 = self.physicalBlocks["LEAF_2"] else { return }
                
                self.recursivelyPopulate(from: leaf1, depth: self.maxDepth)
                self.recursivelyPopulate(from: leaf2, depth: self.maxDepth)

            }
        }
    }
    
    func recursivelyPopulate(from: Block, depth: Int) {
        if depth == 1 {
            return
        } else {
            
            // Add two child nodes to each child
            let child1Node = SCNNode(geometry: SCNSphere(radius: 0.01))
            let child1 = VirtualBlock(type: .leaf, node: child1Node, parent: from)
            let child1ID = UUID().uuidString
            child1.id = child1ID
            child1.node.name = child1ID
            child1.depth = from.depth + 1
        
            let child2Node = SCNNode(geometry: SCNSphere(radius: 0.01))
            let child2 = VirtualBlock(type: .leaf, node: child2Node, parent: from)
            let child2ID = UUID().uuidString
            child2.id = child2ID
            child2.node.name = child2ID
            child2.depth = from.depth + 1

            virtualBlocks[child1.id] = child1
            virtualBlocks[child2.id] = child2
            
            // Add the children to the current node
            // Simply add the connector as a child...
            let connection1 = Connector(start: from, end: child1, depth: from.depth+1)
            connection1.id = "\(String(describing: from.id))-\(String(describing: child1.id))"
            let connection2 = Connector(start: from, end: child2, depth: from.depth+1)
            connection2.id = "\(String(describing: from.id))-\(String(describing: child2.id))"

            from.node.addChildNode(connection1)
            from.node.addChildNode(connection2)
            virtualConnectors[connection1.id] = connection1
            virtualConnectors[connection2.id] = connection2
            from.childBlocks = [child1,child2]

            from.node.addChildNode(child1.node)
            from.node.addChildNode(child2.node)
            
            // relative??
//            let child1Connection = Connector(positionStart: SCNVector3Zero, positionEnd: child1.position, radius: 0.005, color: UIColor.white)
//            let child2Connection = Connector(positionStart: SCNVector3Zero, positionEnd: child2.position, radius: 0.005, color: UIColor.white)
//            child1Connection.name = "\(String.init(describing: child1.id))-C"
//            child2Connection.name = "\(String.init(describing: child2.id))-C"
//
//            virtualConnectors[child1.id] = child1Connection
//            virtualConnectors[child2.id] = child2Connection
//            from.connector1 = child1Connection
//            from.connector2 = child2Connection
//            from.node.addChildNode(child1Connection)
//            from.node.addChildNode(child2Connection)
//
//            self.sceneView.scene.rootNode.addChildNode(child1Connection)
//            self.sceneView.scene.rootNode.addChildNode(child2Connection)
//
            // Populate one more level
            recursivelyPopulate(from: child1, depth: depth-1)
            recursivelyPopulate(from: child2, depth: depth-1)
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
