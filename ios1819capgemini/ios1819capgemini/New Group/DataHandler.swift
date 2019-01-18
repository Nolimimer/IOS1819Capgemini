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
        static let fileNameModels = "ModelsToIncident.json"
        static var localStorageURL: URL {
            guard let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first else {
                fatalError("Can't access the document directory in the user's home directory.")
            }
            return documentsDirectory.appendingPathComponent(Constants.fileName)
        }
        static var localStorageModelURL: URL {
            guard let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first else {
                fatalError("Can't access the document directory in the user's home directory.")
            }
            return documentsDirectory.appendingPathComponent(Constants.fileNameModels)
        }
    }

    // MARK: Stored Type Properties
    static var objectsToIncidents = [String: [Incident]]()
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
            incidents = []
            objectsToIncidents = try JSONDecoder().decode([String : [Incident]].self, from: data)
            for (_, incidents) in objectsToIncidents {
                for incident in incidents {
                    for attachment in incident.attachments {
                        attachment.attachment.reevaluatePath()
                    }
                    self.incidents.append(incident)
                }
            }
        } catch _ {
            print("Could not load incidents, DataHandler uses no incident")
        }
        
        do {
            let fileWrapper = try FileWrapper(url: Constants.localStorageModelURL, options: .immediate)
            guard let data = fileWrapper.regularFileContents else {
                throw NSError()
            }
            incidents = []
            objectsToIncidents = try JSONDecoder().decode([String : [Incident]].self, from: data)
            for (_, incidents) in objectsToIncidents {
                for incident in incidents {
                    for attachment in incident.attachments {
                        attachment.attachment.reevaluatePath()
                    }
                    self.incidents.append(incident)
                }
            }
        } catch _ {
            print("Could not load ar object: [incident] dictionary")
        }
    }
    
    static func saveToJSON() {
        do {
            let data = try JSONEncoder().encode(objectsToIncidents)
            let jsonFileWrapper = FileWrapper(regularFileWithContents: data)
            try jsonFileWrapper.write(to: Constants.localStorageURL,
                                      options: FileWrapper.WritingOptions.atomic,
                                      originalContentsURL: nil)
//            print("Saved incidents!")
        } catch _ {
            print("Could not save incidents")
        }
        do {
            let data = try JSONEncoder().encode(objectsToIncidents)
            let jsonFileWrapper = FileWrapper(regularFileWithContents: data)
            try jsonFileWrapper.write(to: Constants.localStorageModelURL,
                                      options: FileWrapper.WritingOptions.atomic,
                                      originalContentsURL: nil)        } catch _ {
            print("Could not save ar object: [incident] dictionary")
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
            incidents = []
            let fileWrapper = try FileWrapper(url: url, options: .immediate)
            guard let data = fileWrapper.regularFileContents else {
                throw NSError()
            }
            objectsToIncidents = try JSONDecoder().decode([String : [Incident]].self, from: data)
            for (_, incidents) in objectsToIncidents {
                for incident in incidents {
                    for attachment in incident.attachments {
                        attachment.attachment.reevaluatePath()
                    }
                    self.incidents.append(incident)
                }
            }
            print(objectsToIncidents)
        } catch let error {
            print("Could not load incidents, DataHandler uses no incident")
        }
    }
    static func getIncidentsOfObject(identifier: String) -> [Incident] {
        return DataHandler.objectsToIncidents[identifier] ?? []
    }
    
    static func removeIncident(incidentToDelete: Incident) {
        for (index, incident) in incidents.enumerated() where incident.identifier == incidentToDelete.identifier {
             incidents.remove(at: index)
             saveToJSON()
             return
        }
    }
}
