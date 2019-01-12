//
//  DataHandler.swift
//  Incident Tracker
//
//  Created by Daniel Svendsen and Michael Schott on 11/23/18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

// MARK: Imports
import Foundation

// MARK: Datahandler
enum DataHandler {
    
    // MARK: Constants
    private enum Constants {
        static let fileName = "Incident.json"
        static var localStorageURL: URL {
            guard let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first else {
                fatalError("Can't access the document directory in the user's home directory.")
            }
            return documentsDirectory.appendingPathComponent(Constants.fileName)
        }
    }

    // MARK: Stored Type Properties
    static var incidents: [Incident] = []
    static var largestID = 0
    static var currentSegmentFilter = Filter.showAll.rawValue // Show All by default
    static var openIncidents = [Incident]()
    static var inProgressIncidents = [Incident]()
    static var resolvedIncidents = [Incident]()
  
    // MARK: Computed Instance Properties
    static var nextIncidentID: Int {
        largestID = Int(arc4random())
        return largestID
    }
    
    static func incident(withId id: Int) -> Incident? {
        return incidents.first(where: { $0.identifier == id })
    }
    static func incident(withId id: String) -> Incident? {
        return incidents.first(where: { "\($0.identifier)" == id })
    }

    static func refreshOpenIncidents() {
        openIncidents = incidents.filter({ $0.status == Status.open })
    }
    
    static func refreshInProgressIncidents() {
        inProgressIncidents = incidents.filter({ $0.status == Status.progress })
    }
    
    static func refreshResolvedIncidents() {
        resolvedIncidents = incidents.filter({ $0.status == Status.resolved })
    }
    
    // MARK: Type Methods
    static func loadFromJSON() {
        do {
            let fileWrapper = try FileWrapper(url: Constants.localStorageURL, options: .immediate)
            guard let data = fileWrapper.regularFileContents else {
                throw NSError()
            }
            incidents = try JSONDecoder().decode([Incident].self, from: data)
        } catch _ {
            print("Could not load incidents, DataHandler uses no incident")
        }
    }
    
    static func saveToJSON() {
        do {
            let data = try JSONEncoder().encode(incidents)
            let jsonFileWrapper = FileWrapper(regularFileWithContents: data)
            try jsonFileWrapper.write(to: Constants.localStorageURL,
                                      options: FileWrapper.WritingOptions.atomic,
                                      originalContentsURL: nil)
//            print("Saved incidents!")
        } catch _ {
            print("Could not save incidents")
        }
    }
    
    static func getJSON() -> Data? {
        do {
            let data = try JSONEncoder().encode(incidents)
            return data
        } catch _ {
            return nil
        }
    }
    
    static func loadFromJSON(url: URL) {
        do {
            let fileWrapper = try FileWrapper(url: url, options: .immediate)
            guard let data = fileWrapper.regularFileContents else {
                throw NSError()
            }
            incidents = try JSONDecoder().decode([Incident].self, from: data)
            for incident in incidents {
                for attachment in incident.attachments {
                    attachment.attachment.reevaluatePath()
                }
            }
        } catch _ {
            print("Could not load incidents, DataHandler uses no incident")
        }
    }
    
    static func removeIncident(incidentToDelete: Incident) {
        for (index, incident) in incidents.enumerated() where incident.identifier == incidentToDelete.identifier {
             incidents.remove(at: index)
             saveToJSON()
             return
        }
    }
}
