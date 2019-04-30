//
//  ARKit+Extensions.swift
//  PlantCraft
//
//  Created by Tyler Angert on 4/29/19.
//  Copyright © 2019 Tyler Angert. All rights reserved.
//

import Foundation
import ARKit

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
}
