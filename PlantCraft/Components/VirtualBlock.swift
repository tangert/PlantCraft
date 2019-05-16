//
//  VirtualBlock.swift
//  PlantCraft
//
//  Created by Tyler Angert on 5/14/19.
//  Copyright © 2019 Tyler Angert. All rights reserved.
//

import Foundation
import ARKit

class VirtualBlock: Block, Recursable {    
    var parent: Block!
    var childBlocks: [VirtualBlock]!
    var depth: Int!
    var id: String!
    var type: BlockType!
    var connectors: [Connector]!
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
    
    init(type: BlockType, parent: Block) {
        self.type = type
        self.parent = parent
        self.childBlocks = [VirtualBlock]()
        self.connectors = [Connector]()
    }
    
    init(type: BlockType, node: SCNNode, parent: Block) {
        self.type = type
        self.node = node
        self.parent = parent
        self.childBlocks = [VirtualBlock]()
    }
    
    func update(node: SCNNode) {
        self.node = node
    }
}
