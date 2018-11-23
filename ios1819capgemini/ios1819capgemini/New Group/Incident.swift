//
//  Incident.swift
//  ios1819capgemini
//
//  Created by MembrainDev on 19.11.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

import Foundation

public class Incident: Codable {
    private var identifier: Int = 0
    private var type: IncidentType?
    private var date: Date
    private var description: String
    private var attachments: [Attachment]?
    
    init(type: IncidentType?, date: Date, description: String) {
        self.type = type
        self.date = date
        self.description = description
        attachments = [Attachment]()
        identifier = self.identifier + 1
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

enum IncidentType: String, Codable {
    case scratch
    case dent
}
