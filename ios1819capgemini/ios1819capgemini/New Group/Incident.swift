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
    
    // MARK: Initializers
    init(type: IncidentType?, description: String) {
        self.type = type
        self.description = description
        date = Date()
        identifier = DataHandler.nextIncidentID
        attachments = [Attachment]()
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

// MARK: - Extension: Equatable
extension Incident: Equatable {
    public static func == (lhs: Incident, rhs: Incident) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}
