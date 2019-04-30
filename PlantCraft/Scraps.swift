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
