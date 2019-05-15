//
//  Connector.swift
//  PlantCraft
//
//  Created by Tyler Angert on 4/29/19.
//  Copyright © 2019 Tyler Angert. All rights reserved.
//

import Foundation
import SceneKit

class Connector: SCNNode {

    var startNode = SCNNode()
    var endNode = SCNNode()
    let zAxisNode = SCNNode()
    let cylinderNode = SCNNode()
    var radius: CGFloat!
    var startBlock: Block!
    var endBlock: Block!
    var children = [Connector]()
    var depth: Int!
    var id: String!
    
    init(start: Block, end: Block, depth: Int) {
        super.init()
        startBlock = start
        endBlock = end
        self.depth = depth
        startNode = startBlock.node!
        endNode = endBlock.node!
        setupGeometry(positionStart: startNode.position, positionEnd: endNode.position, radius: 0.001, color: UIColor.white)
    }
    
    init(positionStart: SCNVector3, positionEnd: SCNVector3, radius: CGFloat, color: UIColor){
        super.init()
        setupGeometry(positionStart: positionStart, positionEnd: positionEnd, radius: radius, color: color)
    }
    
    func setupGeometry(positionStart: SCNVector3, positionEnd: SCNVector3, radius: CGFloat, color: UIColor) {
        let height = CGFloat(GLKVector3Distance(SCNVector3ToGLKVector3(positionStart), SCNVector3ToGLKVector3(positionEnd)))
        self.radius = radius
        
        startNode.position = positionStart
        endNode.position = positionEnd
        zAxisNode.eulerAngles.x = .pi/2
        
        cylinderNode.geometry?.firstMaterial?.diffuse.contents = color
        updateCylinder(startPos: positionStart, endPos: positionEnd)
        zAxisNode.addChildNode(cylinderNode)
        self.addChildNode(endNode)
        self.addChildNode(startNode)
        
        if (positionStart.x > 0.0 && positionStart.y < 0.0 && positionStart.z < 0.0 && positionEnd.x > 0.0 && positionEnd.y < 0.0 && positionEnd.z > 0.0)
        {
            endNode.addChildNode(zAxisNode)
            endNode.constraints = [ SCNLookAtConstraint(target: startNode) ]
            self.addChildNode(endNode)
            
        }
        else if (positionStart.x < 0.0 && positionStart.y < 0.0 && positionStart.z < 0.0 && positionEnd.x < 0.0 && positionEnd.y < 0.0 && positionEnd.z > 0.0)
        {
            endNode.addChildNode(zAxisNode)
            endNode.constraints = [ SCNLookAtConstraint(target: startNode) ]
            self.addChildNode(endNode)
            
        }
        else if (positionStart.x < 0.0 && positionStart.y > 0.0 && positionStart.z < 0.0 && positionEnd.x < 0.0 && positionEnd.y > 0.0 && positionEnd.z > 0.0)
        {
            endNode.addChildNode(zAxisNode)
            endNode.constraints = [ SCNLookAtConstraint(target: startNode) ]
            self.addChildNode(endNode)
            
        }
        else if (positionStart.x > 0.0 && positionStart.y > 0.0 && positionStart.z < 0.0 && positionEnd.x > 0.0 && positionEnd.y > 0.0 && positionEnd.z > 0.0)
        {
            endNode.addChildNode(zAxisNode)
            endNode.constraints = [ SCNLookAtConstraint(target: startNode) ]
            self.addChildNode(endNode)
            
        }
        else
        {
            startNode.addChildNode(zAxisNode)
            startNode.constraints = [ SCNLookAtConstraint(target: endNode) ]
            self.addChildNode(startNode)
        }
    }
    
    func update(startPos: SCNVector3, endPos: SCNVector3) {
        startNode.position = startPos
        endNode.position = endPos
        endNode.constraints = [ SCNLookAtConstraint(target: startNode) ]
        startNode.constraints = [ SCNLookAtConstraint(target: endNode) ]
        updateCylinder(startPos: startPos, endPos: endPos)
    }
    
    func updateCylinder(startPos: SCNVector3, endPos: SCNVector3) {
        let height = CGFloat(GLKVector3Distance(SCNVector3ToGLKVector3(startPos), SCNVector3ToGLKVector3(endPos)))
        let cylinderGeometry = SCNCylinder(radius: self.radius, height: height)
        cylinderNode.geometry = cylinderGeometry
        cylinderNode.position.y = Float(-height/2)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
