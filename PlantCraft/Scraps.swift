//
//  Scraps.swift
//  PlantCraft
//
//  Created by Tyler Angert on 4/30/19.
//  Copyright © 2019 Tyler Angert. All rights reserved.
//

import Foundation

// find the FROM orthogonal vector relative to the TO's local x plane!
// then find the angle between the FROM and its ORTHO
// that is the angle to store and that is recursed.
// Virtual plane node
// does the projection need to depend on the phones orientation?
//            let vector : SCNVector3 = blocks[to]!.position - blocks[from]!.position
//            let projection = SCNVector3(vector.x, 0.0, vector.z).normalized
//            let angle = blocks[from]!.position.angleBetweenVectors(projection)
//            print("\(from) -> \(to)")
//            print(angles * (180 / .pi))
//            print("\n")
//            let angles = blocks[from]!.eulerAngles

////  PlantCraft
////
////  Created by Tyler Angert on 4/27/19.
////  Copyright © 2019 Tyler Angert. All rights reserved.
////
//
//import UIKit
//import SceneKit
//import ARKit
//
//// TODO: remove connection nodes when image is removed from scene
//class Pattern {
//
//    var blocks: [String: Block]!
//    var connections:[String:String]!
//
//    init(blocks: [String: Block], connections: [String:String]){
//        self.blocks = blocks
//        self.connections = connections
//    }
//}
//
//protocol Repeatable {
//
//}
//
//class BaseBlock {
//
//}
//
//class VirtualBlock {
//
//}
//
//
//class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
//
//    @IBOutlet var sceneView: ARSCNView!
//
//    // A serial queue for thread safety when modifying SceneKit's scene graph.
//    let updateQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).serialSCNQueue")
//
//    // MARK: - Visual stuff
//    var blocks = [String: Block]()
//    var connectors = [String: Connector]()
//    var virtualBlocks = [String: SCNNode]()
//    var testNode: SCNNode!
//    var dummyNode = SCNNode()
//
//    // Keeps references between blocks
//    var connections = [String:String]()
//
//    //    // Stores high level patterns to be repeated
//    //    var patterns = [String: [String: String]]()
//
//    // MARK: - User parameters
//    // Level of recursion
//    var depthLevel: Int = 1
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        // Set the view's delegate
//        sceneView.delegate = self
//
//        // Show statistics such as fps and timing information
//        sceneView.showsStatistics = true
//
//        // Create a new scene
//        let scene = SCNScene()
//        sceneView.session.delegate = self
//        sceneView.debugOptions = [.showCameras ,.showBoundingBoxes, .showWorldOrigin, .showConstraints]
//
//        // Set the scene to the view
//        sceneView.scene = scene
//
//
//        let geo = SCNSphere(radius: 0.0075)
//        geo.firstMaterial?.diffuse.contents = UIColor.red
//        testNode = SCNNode(geometry: geo)
//        sceneView.scene.rootNode.addChildNode(testNode)
//    }
//
//    override func viewWillAppear(_ animated: Bool) {
//        super.viewWillAppear(animated)
//
//        guard let refImages = ARReferenceImage.referenceImages(inGroupNamed: "AR Resources", bundle: Bundle.main) else {
//            fatalError("Missing expected asset catalog resources.")
//        }
//
//        // Create a session configuration
//        let configuration = ARImageTrackingConfiguration()
//        configuration.trackingImages = refImages
//        configuration.maximumNumberOfTrackedImages = 4
//
//        // Run the view's session
//        sceneView.session.run(configuration, options: ARSession.RunOptions(arrayLiteral: [.resetTracking, .removeExistingAnchors]))
//    }
//
//    override func viewWillDisappear(_ animated: Bool) {
//        super.viewWillDisappear(animated)
//        // Pause the view's session
//        sceneView.session.pause()
//    }
//
//    // MARK: - ARSessionDelegate
//    func session(_ session: ARSession, didUpdate frame: ARFrame) {
//    }
//
//    // Function for parsing the visual input
//    // actually no this needs to be recursive
//    func parseAnchors() {
//        for (name, block) in blocks {
//
//            // Recursion block can never be FROM.
//            // Everything always connects TO it.
//            if block.type == .recurse  {
//                continue
//            }
//
//            // If the block has already been connected to
//            if connections.values.contains(name) && block.type != .recurse {
//                continue
//            }
//
//            // only go on if the block actually has something next to it
//            guard  let next = findNext(from: block) else { continue }
//
//            // Update the connections based on the block positions
//            connections[name] = next.id
//        }
//    }
//
//
//    // Figure out this function. Finding the next block.
//    func findNext(from: Block) -> Block? {
//
//        // Adjust to look within a search rdius for each block
//
//        var next: Block?
//        var minDist = Float.greatestFiniteMagnitude
//
//        for (name, block) in blocks where name != from.id! {
//            // minimum distance given the direction/orientation of the anchor
//            let dist = (from.position - block.position).magnitude
//
//            // Assign the new next block
//            if dist < minDist {
//                minDist = dist
//                next = block
//            }
//        }
//        return next
//    }
//
//    func renderPlant() {
//
//        // For each iteration
//        // Draw the pattern
//        // Get the pattern?
//        updateBlocks()
//        // Now that the from node is properly rotated,
//        // you can use that after you duplicate to simulate recursion
//    }
//
//    func updateBlocks() {
//
//        // STEP 1: UPDATE THE CONNECTIONS FROM CURRENT BLOCKS
//        for (from, to) in connections {
//            guard let f = blocks[from] else { return }
//            guard let t = blocks[to] else { return }
//            guard let c = connectors[from] else { return }
//
//            // Update the from block to "look" at the to block.
//            //f.node.look(at: t.position)
//            c.update(startPos: f.position, endPos: t.position)
//        }
//
//        //        print(connections)
//
//
//        // Generalize to more than one leaf and patterns
//
//        // This is the CENTER of the pattern
//        guard let repeatBlock = blocks["REPEAT"] else { return }
//        guard let growBlock = blocks["GROW"] else { return }
//        guard let leafBlock = blocks["LEAF"] else { return }
//
//
//        // nearest block below the repeat as the basee
//
//        let angle = getAngle(v1: growBlock.position, v2: repeatBlock.position, v3: leafBlock.position, degrees: false)
//
//        // Figure out how to get node look at rotation
//        let offsetVector: SCNVector3 = repeatBlock.position - growBlock.position
//        let translationVector = SCNVector3(0, offsetVector.y, 0)
//
//        testNode.position = leafBlock.position
//        testNode.localTranslate(by: translationVector)
//        testNode.eulerAngles.z = angle
//
//    }
//
//    func getAngle(v1: SCNVector3, v2: SCNVector3, v3: SCNVector3, degrees: Bool) -> Float {
//        let a = pow(v2.x - v1.x,2) + pow(v2.y-v1.y,2) + pow(v2.z-v1.z,2)
//        let b = pow(v2.x-v3.x,2) + pow(v2.y-v3.y,2) + pow(v2.z-v3.z,2)
//        let c = pow(v3.x-v1.x,2) + pow(v3.y-v1.y,2) + pow(v3.z-v1.z,2)
//
//        var division: Float
//        if degrees {
//            division = 360 / (2 * Float.pi)
//        } else {
//            division = 1
//        }
//        return (acos( (a+b-c) / sqrt(4*a*b))) * Float(division)
//    }
//
//
//    // MARK: - ARSCNViewDelegate
//
//    // Override to create and configure nodes for anchors added to the view's session.
//    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
//        let node = SCNNode()
//        return node
//    }
//
//    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
//        // Make sure the image  anchor exists
//        guard let imageAnchor = anchor as? ARImageAnchor else { return }
//
//        // Update the block
//        blocks[imageAnchor.name!]?.update(node: node, anchor: imageAnchor)
//
//        // Reparse and rerender
//        parseAnchors()
//        renderPlant()
//    }
//
//
//    // Adds the marker nodes to the scene.
//    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
//
//        guard let imageAnchor = anchor as? ARImageAnchor else { return }
//        let id = imageAnchor.name!
//
//        let type: BlockType!
//
//        // Abstract this into Block, so that it parses the image anchor name automatically
//        if id.contains("grow"){
//            type = .grow
//        } else if id.contains("repeat") {
//            type = .recurse
//        } else {
//            type = .leaf
//        }
//
//        // Add the block
//        let block = Block(type: type, node: node, anchor: imageAnchor)
//        blocks[imageAnchor.name!] = block
//
//        let connector = Connector(positionStart: block.position, positionEnd: SCNVector3Zero, radius: 0.0075, color: UIColor.yellow)
//        connector.renderingOrder = 2
//        connectors[imageAnchor.name!] = connector
//
//        // Delegate rendering tasks to our `updateQueue` thread to keep things thread-safe!
//        updateQueue.async {
//
//            let physicalWidth = imageAnchor.referenceImage.physicalSize.width
//            let physicalHeight = imageAnchor.referenceImage.physicalSize.height
//
//            // Create a plane geometry to visualize the initial position of the detected image
//            let mainPlane = SCNPlane(width: physicalWidth, height: physicalHeight)
//            var color: UIColor!
//
//            if imageAnchor.name!.contains("grow") {
//                color = UIColor.brown
//            } else if imageAnchor.name!.contains("leaf") {
//                color = UIColor.orange
//            } else if imageAnchor.name! == "Leaf-QR" {
//                color = UIColor.green
//            } else {
//                color = UIColor.blue
//            }
//
//            // Assign the color
//            mainPlane.firstMaterial?.diffuse.contents = color
//
//            // Create a SceneKit root node with the plane geometry to attach to the scene graph
//            // This node will hold the virtual UI in place
//            //  x reference
//            let xReferenceNode = SCNNode(geometry: mainPlane)
//            xReferenceNode.eulerAngles.x = -.pi
//            xReferenceNode.renderingOrder = -1
//            xReferenceNode.opacity = 0.5
//
//            // This is the marker
//            let markerNode = SCNNode(geometry: mainPlane)
//            markerNode.eulerAngles.x = -.pi/2
//            markerNode.renderingOrder = 0
//            markerNode.opacity = 0.25
//
//            let sphereNode = SCNNode(geometry: SCNSphere(radius: 0.015))
//            sphereNode.renderingOrder = 1
//
//            // Add the plane visualization to the scene
//            node.addChildNode(xReferenceNode)
//            node.addChildNode(markerNode)
//            node.addChildNode(sphereNode)
//
//            if type != .recurse {
//                connector.renderingOrder = 2
//                node.addChildNode(connector)
//
//            }
//
//            print(self.connectors)
//            if type != .recurse {
//                self.sceneView.scene.rootNode.addChildNode(connector)
//            }
//        }
//    }
//
//    func session(_ session: ARSession, didFailWithError error: Error) {
//        // Present an error message to the user
//
//    }
//
//    func sessionWasInterrupted(_ session: ARSession) {
//        // Inform the user that the session has been interrupted, for example, by presenting an overlay
//
//    }
//
//    func sessionInterruptionEnded(_ session: ARSession) {
//        // Reset tracking and/or remove existing anchors if consistent tracking is required
//
//    }
//}


//
//func getAngle(v1: SCNVector3, v2: SCNVector3, v3: SCNVector3, degrees: Bool) -> Float {
//    let a = pow(v2.x - v1.x,2) + pow(v2.y-v1.y,2) + pow(v2.z-v1.z,2)
//    let b = pow(v2.x-v3.x,2) + pow(v2.y-v3.y,2) + pow(v2.z-v3.z,2)
//    let c = pow(v3.x-v1.x,2) + pow(v3.y-v1.y,2) + pow(v3.z-v1.z,2)
//
//    var division: Float
//    if degrees {
//        division = 360 / (2 * Float.pi)
//    } else {
//        division = 1
//    }
//    return (acos( (a+b-c) / sqrt(4*a*b))) * Float(division)
//}
