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
        static let fileNameSingleCarPart = "carPart.json"
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
        static var localStorageSingleCarPartURL : URL {
            guard let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first else {
                fatalError("Can't access the document directory in the user's home directory.")
            }
            return documentsDirectory.appendingPathComponent(Constants.fileNameSingleCarPart)
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
                    if let previewPictureURL = DataHandler.matchPreviewPicture(carPart: file) {
                        let carPart = CarPart(incidents: [], filePath: file, picturePath: previewPictureURL)
                        if !carParts.contains(where: { $0.name == carPart.name }) {
                            DataHandler.carParts.append(carPart)
                        }
                    }

                }
            }
        } catch {
            print("Error loading custom scans")
        }
//        for carPart in DataHandler.carParts {
//            print("car part picture : \(carPart.picturePath?.lastPathComponent)")
//        }
        DataHandler.saveToJSON()
    }
    static func matchPreviewPicture(carPart: URL) -> URL? {
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)

        if let dirPath = paths.first {
            let name = "\(carPart.lastPathComponent.dropLast(".arobject".count).lowercased()).jpg"
            let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent(name)
            return imageURL
        }
        return nil
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
        }
        do {
            let fileWrapper = try FileWrapper(url: Constants.localStorageModelURL, options: .immediate)
            guard let data = fileWrapper.regularFileContents else {
                throw NSError()
            }
            objectsToIncidents = try JSONDecoder().decode([String: [Incident]].self, from: data)
        } catch _ {
        }
        
        do {
            let fileWrapper = try FileWrapper(url: Constants.localStorageModelURL, options: .immediate)
            guard let data = fileWrapper.regularFileContents else {
                throw NSError()
            }
            carParts = try JSONDecoder().decode([CarPart].self, from: data)
            for carPart in carParts {
                carPart.reevaluateFilePath()
                carPart.reevaluatePicturePath()
                for incident in carPart.incidents {
                    for attachment in incident.attachments {
                        attachment.attachment.reevaluatePath()
                    }
                }
            }
        } catch _ {
        }
    }
    
    static func saveToJSON() {
        do {
            let data = try JSONEncoder().encode(objectsToIncidents)
            let jsonFileWrapper = FileWrapper(regularFileWithContents: data)
            try jsonFileWrapper.write(to: Constants.localStorageModelURL,
                                      options: FileWrapper.WritingOptions.atomic,
                                      originalContentsURL: nil)
        } catch _ {
        }
        do {
            let data = try JSONEncoder().encode(carParts)
            let jsonFileWrapper = FileWrapper(regularFileWithContents: data)
            try jsonFileWrapper.write(to: Constants.localStorageModelURL,
                                      options: FileWrapper.WritingOptions.atomic,
                                      originalContentsURL: nil)
        } catch _ {
        }
    }
    
    static func saveToJSON(carPart: CarPart) {
        do {
            let data = try JSONEncoder().encode(carPart)
            let jsonFileWrapper = FileWrapper(regularFileWithContents: data)
            try jsonFileWrapper.write(to: Constants.localStorageSingleCarPartURL,
                                      options: FileWrapper.WritingOptions.atomic,
                                      originalContentsURL: nil)
        } catch _ {
        }
    }

    static func getJSONCurrentCarPart() -> Data? {
        do {
            let fileWrapper = try FileWrapper(url: Constants.localStorageSingleCarPartURL, options: .immediate)
            guard let data = fileWrapper.regularFileContents else {
                throw NSError()
            }
            return data
        } catch _ {
            print("Could not load incidents, DataHandler uses no incident")
            return nil
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
    
//    static func getJSON(carPart: CarPart) -> Data? {
//        do {
//            let fileWrapper = try FileWrapper
//        }
//    }
    
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
        }
        do {
            let fileWrapper = try FileWrapper(url: url, options: .immediate)
            guard let data = fileWrapper.regularFileContents else {
                throw NSError()
            }
            carParts = try JSONDecoder().decode([CarPart].self, from: data)
            for carPart in carParts {
                carPart.reevaluateFilePath()
                carPart.reevaluatePicturePath()
                for incident in carPart.incidents {
                    for attachment in incident.attachments {
                        attachment.attachment.reevaluatePath()
                    }
                }
            }
        } catch _ {
        }
        do {
            let fileWrapper = try FileWrapper(url: url, options: .immediate)
            guard let data = fileWrapper.regularFileContents else {
                throw NSError()
            }
            let carPart = try JSONDecoder().decode(CarPart.self, from: data)
            carPart.reevaluatePicturePath()
            carPart.reevaluateFilePath()
            for incident in carPart.incidents {
                for attachment in incident.attachments {
                    attachment.attachment.reevaluatePath()
                }
            }
            //swiftlint:disable all
            for (index, part) in carParts.enumerated() {
                if part.name == carPart.name {
                    carParts.remove(at: index)
                }
            }
            carParts.append(carPart)
        } catch _ {
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
    
    static func saveCarPart() {
        if ARViewController.selectedCarPart == nil {
            return
        }
        if DataHandler.incidents.isEmpty {
            return
        }
        ARViewController.selectedCarPart?.incidents = DataHandler.incidents
        ModelViewController.carPart = ARViewController.selectedCarPart
        DataHandler.incidents = []
        if let carPart = ModelViewController.carPart {
            if DataHandler.containsCarPart(carPart: carPart) {
                DataHandler.replaceCarPart(carPart: carPart)
            } else {
                DataHandler.setCarParts()
            }
        }
    }
    //swiftlint:disable all
    static func removePreviewPictures(files: [String]) {
        let fileManager = FileManager.default
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        for fileToDelete in files {
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
                for file in fileURLs {
                    if file.lastPathComponent == "\(fileToDelete)" {
                        try fileManager.removeItem(at: file.absoluteURL)
                    }
                }
            } catch {
                print("Error loading custom scans")
            }
        }
    }
    
    static func setPreviewPictures(files: [String]) {
        if let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last {
            for file in files {
                let fileURL = documentsDirectory.appendingPathComponent(file)
                do {
                    if try fileURL.checkResourceIsReachable() {
                        print("file exist")
                    } else {
                        print("file doesnt exist")
                        do {
                            try Data().write(to: fileURL)
                        } catch {
                            print("an error happened while creating the file")
                        }
                    }
                } catch {
                }
            }
        }
    }
}
