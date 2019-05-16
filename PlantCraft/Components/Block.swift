//
//  Block.swift
//  PlantCraft
//
//  Created by Tyler Angert on 5/14/19.
//  Copyright © 2019 Tyler Angert. All rights reserved.
//

import Foundation
import ARKit

protocol Block: class {
    var type: BlockType! { get set }
    var depth: Int! { get set }
    var childBlocks: [VirtualBlock]! { get set }
    var connectors: [Connector]! { get set }
    var node: SCNNode!  { get set }
    var id: String! { get }
    var position: SCNVector3! { get }
    var transform: SCNMatrix4! { get }
    var rotation: SCNVector4! { get }
    var eulerAngles: SCNVector3! { get }
}

protocol Detectable {
    var anchor: ARImageAnchor! { get set }
}

protocol Recursable {
    var parent: Block! { get set }
}

enum BlockType {
    case grow
    case recurse
    case leaf
}
