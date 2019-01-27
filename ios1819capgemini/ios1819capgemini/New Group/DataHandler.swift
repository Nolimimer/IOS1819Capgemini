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
    static var carParts = [CarPart]()
    static var objectsToIncidents = [String: [Incident]]()
    static var incidents: [Incident] = []
    static var largestID = 0
  
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
    
    static func setCarParts() {
        let fileManager = FileManager.default
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            for file in fileURLs {
                if file.lastPathComponent.hasSuffix(".arobject") {
                    let carPart = CarPart(incidents: [], filePath: file)
                    if !carParts.contains(where: { $0.name == carPart.name }) {
                        DataHandler.carParts.append(carPart)
                    }
                }
            }
        } catch {
            print("Error loading custom scans")
        }
    }
    
    // MARK: Type Methods
    static func loadFromJSON() {
        do {
            let fileWrapper = try FileWrapper(url: Constants.localStorageModelURL, options: .immediate)
            guard let data = fileWrapper.regularFileContents else {
                throw NSError()
            }
            carParts = try JSONDecoder().decode([CarPart].self, from: data)
        } catch _ {
            print("Could not load ar object: [incident] dictionary")
        }
        
        do {
            let fileWrapper = try FileWrapper(url: Constants.localStorageModelURL, options: .immediate)
            guard let data = fileWrapper.regularFileContents else {
                throw NSError()
            }
            objectsToIncidents = try JSONDecoder().decode([String: [Incident]].self, from: data)
        } catch _ {
            print("Could not load ar object: [incident] dictionary")
        }
        do {
            let fileWrapper = try FileWrapper(url: Constants.localStorageModelURL, options: .immediate)
            guard let data = fileWrapper.regularFileContents else {
                throw NSError()
            }
            carParts = try JSONDecoder().decode([CarPart].self, from: data)
            for carPart in carParts {
                carPart.reevaluateFilePath()
                for incident in carPart.incidents {
                    for attachment in incident.attachments {
                        attachment.attachment.reevaluatePath()
                    }
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
            try jsonFileWrapper.write(to: Constants.localStorageModelURL,
                                      options: FileWrapper.WritingOptions.atomic,
                                      originalContentsURL: nil)        } catch _ {
            print("Could not save ar object: [incident] dictionary")
        }
        do {
            let data = try JSONEncoder().encode(carParts)
            let jsonFileWrapper = FileWrapper(regularFileWithContents: data)
            try jsonFileWrapper.write(to: Constants.localStorageModelURL,
                                      options: FileWrapper.WritingOptions.atomic,
                                      originalContentsURL: nil)
            print(carParts)

        } catch _ {
            print("Could not save ar object: [incident] dictionary")
                
        }
        
    }
    
    static func getJSON() -> Data? {
        do {
            let fileWrapper = try FileWrapper(url: Constants.localStorageModelURL, options: .immediate)
            guard let data = fileWrapper.regularFileContents else {
                throw NSError()
            }
            return data
        } catch _ {
            print("Could not load incidents, DataHandler uses no incident")
            return nil
        }
    }
    
    static func loadFromJSON(url: URL) {
        
        do {
            let fileWrapper = try FileWrapper(url: url, options: .immediate)
            guard let data = fileWrapper.regularFileContents else {
                throw NSError()
            }
            objectsToIncidents = try JSONDecoder().decode([String: [Incident]].self, from: data)
            
            for (_, incidents) in objectsToIncidents {
                for incident in incidents {
                    for attachment in incident.attachments {
                        attachment.attachment.reevaluatePath()
                    }
                }
            }
        } catch _ {
            print("Could not load ar object: [incident] dictionary")
        }
        do {
            let fileWrapper = try FileWrapper(url: url, options: .immediate)
            guard let data = fileWrapper.regularFileContents else {
                throw NSError()
            }
            carParts = try JSONDecoder().decode([CarPart].self, from: data)
            for carPart in carParts {
                carPart.reevaluateFilePath()
                for incident in carPart.incidents {
                    for attachment in incident.attachments {
                        attachment.attachment.reevaluatePath()
                    }
                }
            }
        } catch _ {
            print("Could not load ar object: [incident] dictionary")
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
    static func containsIncidentIdentifier(incident: Incident) -> Bool {
        for incidents in DataHandler.incidents where incident.identifier == incidents.identifier {
                return true
        }
        return false
    }
    
    static func getIndexOfIncident(incident: Incident) -> Int? {
        return DataHandler.incidents.firstIndex(where: { $0.identifier == incident.identifier })
    }
    
    static func getIndexOfCarPart(carPart: CarPart) -> Int? {
        return DataHandler.carParts.firstIndex(where: { $0.name == carPart.name })
    }
    
    static func replaceIncident(incident: Incident) {
        guard let index = DataHandler.incidents.firstIndex(where: { $0.identifier == incident.identifier }) else {
            return
        }
        DataHandler.incidents[index] = incident
    }
    static func replaceCarPart(carPart: CarPart) {
        if DataHandler.carParts.contains(where: { $0.name == carPart.name }) {
            DataHandler.carParts[DataHandler.getIndexOfCarPart(carPart: carPart)!] = carPart
        }
    }
    
    static func containsCarPart(carPart: CarPart) -> Bool {
        return DataHandler.carParts.contains(where: { $0.name == carPart.name })
    }
}
