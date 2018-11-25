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
    var identifier: Int
    var type: IncidentType?
    var description: String
    var date: Date
    var attachments: [Attachment]?
    
    // MARK: Initializers
    init(type: IncidentType?, description: String) {
        self.type = type
        self.description = description
        date = Date()
        identifier = DataHandler.nextIncidentID
        attachments = [Attachment]()
    }
    
    private func suggest() -> IncidentType? {
        return nil
    }
    
    public func edit() {
        
    }
    
    public func delete() {
        
    }
    
    public func resolve() {
        
    }
    
    
}

 // MARK: Constants
enum IncidentType: String, Codable {
    case scratch
    case dent
}

// MARK: - Extension: Equatable
extension Incident: Equatable {
    public static func == (lhs: Incident, rhs: Incident) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
