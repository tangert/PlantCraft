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
    var blocks = [String: Block]()
//    var cyl = SCNNode()
    
    // Have to store the tree of images/commands
    
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
        configuration.maximumNumberOfTrackedImages = 10
        
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
        // iterate through the current anchords
//        guard let anchors = self.anchors else { return }
//        guard let g = anchors["GROW"] else { return }
//        guard let r = anchors["REPEAT"] else { return }
//
        
//        print(g.transform.position())
//        print(r.transform.position())
        
//        for (name, anchor) in anchors {
//
//        }
//
        // First task: get a line to draw between the image markers
//        cyl = makeCylinder(positionStart: g.transform.position(),
//                     positionEnd: r.transform.position(),
//                     radius: 0.01,
//                     color: UIColor.blue,
//                     transparency: 1.0)
        
        
        parseAnchors()
        
    }
    
    // Function for parsing the visual input
    // actually no this needs to be recursive
    func parseAnchors() {
        // 1. Look for the start marker
        guard let start = self.blocks["GROW"] else { return }
        
        // 2. Find the next marker to go to
        // Fill up a history list of the types of blocks that have been encountered
        // var history: [BlockType]!
        
        // Find next for each
        // This is On^2
        
        
//        print(start.rotation)
        
//        print("FROM: \(block.id!), TO: \(next.id!)")
        
        var parsedBlocks = blocks
        
        for (name, block) in parsedBlocks {
            
            let next = findNext(from: block)
            parsedBlocks[name] = nil
            
//            print("FROM: \(block.id!), TO: \(next.id!)")

        }
//
//        print("\n")
        
    }
    
    func findNext(from: Block) -> Block {
        
        var next: Block!
        var minDist = Float.greatestFiniteMagnitude
        
        for (name, block) in blocks where name != from.id! {
            // minimum distance given the direction/orientation of the anchor
            let dist = (from.position - block.position).magnitude
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
        
//        print("name: \(imageAnchor.name!)")
//        print("orientation \(node.orientation)")
//        print("rotation \(node.rotation)")
//        print("euler angles \(node.eulerAngles)")
//        print("\n")

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
    
    
    func makeCylinder(positionStart: SCNVector3, positionEnd: SCNVector3, radius: CGFloat , color: UIColor, transparency: CGFloat) -> SCNNode
    {
        let height = CGFloat(GLKVector3Distance(SCNVector3ToGLKVector3(positionStart), SCNVector3ToGLKVector3(positionEnd)))
        let startNode = SCNNode()
        let endNode = SCNNode()
        
        startNode.position = positionStart
        endNode.position = positionEnd
        
        let zAxisNode = SCNNode()
        zAxisNode.eulerAngles.x = Float(CGFloat(M_PI_2))
        
        let cylinderGeometry = SCNCylinder(radius: radius, height: height)
        cylinderGeometry.firstMaterial?.diffuse.contents = color
        let cylinder = SCNNode(geometry: cylinderGeometry)
        
        cylinder.position.y = Float(-height/2)
        zAxisNode.addChildNode(cylinder)
        
        let returnNode = SCNNode()
        
        if (positionStart.x > 0.0 && positionStart.y < 0.0 && positionStart.z < 0.0 && positionEnd.x > 0.0 && positionEnd.y < 0.0 && positionEnd.z > 0.0)
        {
            endNode.addChildNode(zAxisNode)
            endNode.constraints = [ SCNLookAtConstraint(target: startNode) ]
            returnNode.addChildNode(endNode)
            
        }
        else if (positionStart.x < 0.0 && positionStart.y < 0.0 && positionStart.z < 0.0 && positionEnd.x < 0.0 && positionEnd.y < 0.0 && positionEnd.z > 0.0)
        {
            endNode.addChildNode(zAxisNode)
            endNode.constraints = [ SCNLookAtConstraint(target: startNode) ]
            returnNode.addChildNode(endNode)
            
        }
        else if (positionStart.x < 0.0 && positionStart.y > 0.0 && positionStart.z < 0.0 && positionEnd.x < 0.0 && positionEnd.y > 0.0 && positionEnd.z > 0.0)
        {
            endNode.addChildNode(zAxisNode)
            endNode.constraints = [ SCNLookAtConstraint(target: startNode) ]
            returnNode.addChildNode(endNode)
            
        }
        else if (positionStart.x > 0.0 && positionStart.y > 0.0 && positionStart.z < 0.0 && positionEnd.x > 0.0 && positionEnd.y > 0.0 && positionEnd.z > 0.0)
        {
            endNode.addChildNode(zAxisNode)
            endNode.constraints = [ SCNLookAtConstraint(target: startNode) ]
            returnNode.addChildNode(endNode)
            
        }
        else
        {
            startNode.addChildNode(zAxisNode)
            startNode.constraints = [ SCNLookAtConstraint(target: endNode) ]
            returnNode.addChildNode(startNode)
        }
        
        return returnNode
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
