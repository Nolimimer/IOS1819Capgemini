//
//  Incident.swift
//  ios1819capgemini
//
//  Created by MembrainDev on 19.11.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

// MARK: Imports
import Foundation
import SceneKit

//swiftlint:disable all
// MARK: - Incident
public class Incident: Codable {
    
    let identifier: Int
    let createDate: Date

    private(set) var modifiedDate: Date
    private(set) var type: IncidentType
    private(set) var description: String
    private(set) var status: Status
    private(set) var attachments = [Attachment]()
    let coordinate: Coordinate
    // MARK: Initializers
    init(type: IncidentType, description: String, coordinate: Coordinate) {
        identifier = DataHandler.nextIncidentID
        createDate = Date()
        modifiedDate = createDate
        self.type = type
        self.description = description
        status = .open
        self.coordinate = coordinate
    }
    // MARK: Instance Methods
    func edit(status: Status, description: String, modifiedDate: Date) {
        self.status = status
        self.description = description
        self.modifiedDate = modifiedDate
        
        switch status {
        case .open: self.changePinColor(to: UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.9))
        case .progress: self.changePinColor(to: UIColor(red: 239.0/255.0, green: 196.0/255.0, blue: 0.0, alpha: 0.9))
        case .resolved: self.changePinColor(to: UIColor(red: 22.0/255.0, green: 167.0/255.0, blue: 0.0, alpha: 0.9))
        }
        
    }
    
    func editIncidentType(type: IncidentType) {
        self.type = type
    }
    
    // MARK: Private Instance Methods
    private func suggest() -> IncidentType? {
        return nil
    }
    
    private func changePinColor(to color: UIColor) {
        for node in nodes {
            guard let name = node.name,
                let nodeId = Int(name) else {
                    print("no node found")
                    return
            }
            if nodeId == identifier {
                node.geometry?.materials.first?.diffuse.contents = color
            }
        }
    }
    
    func getCoordinateToVector() -> SCNVector3 {
        var res = SCNVector3.init()
        res.x = coordinate.pointX
        res.y = coordinate.pointY
        res.z = coordinate.pointZ
        return res
    }
    
    func addAttachment(attachment: Attachment) {
        attachments.append(attachment)
    }
    
}

 // MARK: Constants
enum IncidentType: String, Codable {
    case scratch = "Scratch"
    case dent = "Dent"
    case unknown = "Unknown Incident"
}

enum Status: String, Codable {
    case open
    case progress
    case resolved
}

// MARK: - Extension: Equatable
extension Incident: Equatable {
    public static func == (lhs: Incident, rhs: Incident) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

extension Coordinate: Equatable {
    public static func == (lhs: Coordinate, rhs: Coordinate) -> Bool {
        return lhs.description == rhs.description
    }
}

extension IncidentType: CaseIterable {
    
}
