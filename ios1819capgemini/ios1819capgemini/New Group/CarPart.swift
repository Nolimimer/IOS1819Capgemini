//
//  CarPart.swift
//  ios1819capgemini
//
//  Created by MembrainDev on 19.11.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

// MARK: Imports
import Foundation
import ARKit

// MARK: - CarPart
class CarPart: Codable {
    var incidents: [Incident]
    var filePath: URL
    var data: Data?
    
    init(incidents: [Incident], filePath: URL) {
        self.incidents = incidents
        self.filePath = filePath
        do {
            data = try Data(contentsOf: filePath)
        } catch {
            print("could not load arobject")
        }
    }
    
    
}
