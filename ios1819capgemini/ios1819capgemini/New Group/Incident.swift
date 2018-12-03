//
//  Incident.swift
//  ios1819capgemini
//
//  Created by MembrainDev on 19.11.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

// MARK: Imports
import Foundation

// MARK: - Incident
public class Incident: Codable {
    
    let identifier: Int
    let createDate: Date

    private(set) var modifiedDate: Date
    private(set) var type: IncidentType
    private(set) var description: String
    private(set) var status: Status
    private(set) var attachments = [Attachment]()
    
    private var coordinate: Coordinate?
    
    // MARK: Initializers
    init(type: IncidentType, description: String) {
        createDate = Date()
        modifiedDate = createDate
        identifier = DataHandler.nextIncidentID
        status = .open
        
        self.type = type
        self.description = description
    }
    
    convenience init(type: IncidentType, description: String, coordinate: Coordinate) {
        self.init(type: type, description: description)
        self.coordinate = Coordinate(pointX: 0, pointY: 0, pointZ: 0)
    }
    
    // MARK: Instance Methods
    func edit(status: Status, description: String, modifiedDate: Date) {
        self.status = status
        self.description = description
        self.modifiedDate = modifiedDate
    }
    
    // MARK: Private Instance Methods
    private func suggest() -> IncidentType? {
        return nil
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
