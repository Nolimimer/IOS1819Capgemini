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
    var arObjectData: Data?
    var picturePath: URL
    var pictureData: Data?
    
//    convenience init(incidents: [Incident], filePath: URL) {
//        self.incidents = incidents
//        self.name = filePath.lastPathComponent
//        self.filePath = filePath
//        do {
//            data = try Data(contentsOf: filePath)
//        } catch {
//            print("could not load arobject")
//        }
//    }
    
    init(incidents: [Incident], filePath: URL, picturePath: URL) {
        self.incidents = incidents
        self.name = filePath.lastPathComponent
        self.filePath = filePath
        self.picturePath = picturePath
        do {
            pictureData = try Data(contentsOf: picturePath)
        } catch {
            print("could not load preview picture")
        }
        do {
            arObjectData = try Data(contentsOf: filePath)
        } catch {
            print("could not load ar object")
        }
    }
    
    func reevaluateFilePath() {
        do {
            let paths = NSSearchPathForDirectoriesInDomains(
                FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            let documentsDirectory = URL(fileURLWithPath: paths[0])
            let path = documentsDirectory.appendingPathComponent(self.name)
            guard let data = arObjectData else {
                return
            }
            try data.write(to: path, options: [])
            let name = filePath.lastPathComponent
            filePath = URL(fileURLWithPath: "\(paths[0])/\(name)")
        } catch _ {
            print("Could not save data")
            arObjectData = nil
        }
    }
    
    func reevaluatePicturePath() {
        do {
            let paths = NSSearchPathForDirectoriesInDomains(
                FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            let documentsDirectory = URL(fileURLWithPath: paths[0])
            let pictureName = "\(self.name.dropLast(".arobject".count)).jpg"
            let path = documentsDirectory.appendingPathComponent(pictureName)
            guard let data = pictureData else {
                return
            }
            try data.write(to: path, options: [])
            picturePath = URL(fileURLWithPath: "\(paths[0])/\(pictureName)")
        } catch _ {
            print("Could not save picture data")
            pictureData = nil
        }
    }
}
