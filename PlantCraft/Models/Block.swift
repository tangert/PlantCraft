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
    var anchor: ARImageAnchor!
    var position: SCNVector3 {
        return self.anchor.position
    }
    var transform: simd_float4x4!
    var rotation: SCNVector3!
    var id: String!
    
    init(type: BlockType, node: SCNNode, anchor: ARImageAnchor) {
        self.type = type
        self.anchor = anchor
        self.id = anchor.name!
        self.transform = anchor.transform
        self.rotation = node.eulerAngles
    }
}
