//
//  Block.swift
//  PlantCraft
//
//  Created by Tyler Angert on 4/28/19.
//  Copyright © 2019 Tyler Angert. All rights reserved.
//

import Foundation
import ARKit

enum BlockType {
    case grow
    case recurse
    case leaf
}

class Block {
    
    var type: BlockType!
    var node: SCNNode!
    var anchor: ARImageAnchor!
    var position: SCNVector3 {
        return self.node.position
    }
    var transform: SCNMatrix4 {
        return self.node.transform
    }
    var rotation: SCNVector4 {
        return self.node.rotation
    }
    var eulerAngles: SCNVector3 {
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
