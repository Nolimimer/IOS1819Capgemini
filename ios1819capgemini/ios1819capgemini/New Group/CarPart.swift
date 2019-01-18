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
    var name: String
    var filePath: URL
    var data: Data?
    
    init(incidents: [Incident], filePath: URL) {
        self.incidents = incidents
        self.name = filePath.lastPathComponent
        self.filePath = filePath
        do {
            data = try Data(contentsOf: filePath)
        } catch {
            print("could not load arobject")
        }
    }
    
    func reevaluateFilePath() {
        do {
            let paths = NSSearchPathForDirectoriesInDomains(
                FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            let documentsDirectory = URL(fileURLWithPath: paths[0])
            let path = documentsDirectory.appendingPathComponent(self.name)
            guard let data = data else {
                return
            }
            try data.write(to: path, options: [])
            let name = filePath.lastPathComponent
            filePath = URL(fileURLWithPath: "\(paths[0])/\(name)")
        } catch _ {
            print("Could not save data")
            data = nil
        }
    }
    
}
