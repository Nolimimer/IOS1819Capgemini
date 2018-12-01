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
public struct Incident: Codable {
    
    private(set) var identifier: Int
    private(set) var type: IncidentType?
    private(set) var description: String
    private(set) var date: Date
    private var attachments: [Attachment]?
    private var coordinate: Coordinate?
    var status: Status
    private var _modifiedDate: Date?
    var modifiedDate: Date {
        get {
            return _modifiedDate ?? self.date
        }
        set(modifiedDate) {
            _modifiedDate = modifiedDate
        }
    }
    // MARK: Initializers
    init(type: IncidentType?, description: String, coordinate: Coordinate) {
        self.type = type
        self.description = description
        date = Date()
        identifier = DataHandler.nextIncidentID
        attachments = [Attachment]()
        self.status = Status.open
        self.coordinate = Coordinate(pointX: 0, pointY: 0, pointZ: 0)
    }
    
    init(type: IncidentType?, description: String) {
        self.type = type
        self.description = description
        date = Date()
        identifier = DataHandler.nextIncidentID
        self.status = Status.open
        attachments = [Attachment]()
    }
    init(type: IncidentType?, description: String, coordinate: Coordinate, identifier: Int) {
        self.type = type
        self.description = description
        date = Date()
        self.identifier = identifier
        attachments = [Attachment]()
        self.status = Status.open
        self.coordinate = Coordinate(pointX: 0, pointY: 0, pointZ: 0)
    }
    
    // MARK: Instance Methods
    public func edit() {
        
    }
    
    public func delete() {
        
    }
    
    public func resolve() {
        
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
