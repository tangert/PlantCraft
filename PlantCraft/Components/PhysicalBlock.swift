//
//  PhysicalBlock.swift
//  PlantCraft
//
//  Created by Tyler Angert on 5/14/19.
//  Copyright © 2019 Tyler Angert. All rights reserved.
//

import Foundation
import ARKit

class PhysicalBlock: Block, Detectable {
    var type: BlockType!
    var node: SCNNode!
    var depth: Int!
    var childBlocks: [VirtualBlock]!
    var connector1: Connector!
    var connector2: Connector!
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
        self.childBlocks = [VirtualBlock]()
    }
    
    func update(node: SCNNode, anchor: ARImageAnchor) {
        self.node = node
        self.anchor = anchor
    }
}
