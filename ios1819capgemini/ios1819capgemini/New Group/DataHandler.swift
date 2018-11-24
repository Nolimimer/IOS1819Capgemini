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
    
    static var incidents: [Incident] = []
    
    static func loadFromJSON() {
        do {
            let fileWrapper = try FileWrapper(url: Constants.localStorageURL, options: .immediate)
            guard let data = fileWrapper.regularFileContents else {
                throw NSError()
            }
            incidents = try JSONDecoder().decode([Incident].self, from: data)
            print("Decoded \(incidents.count) incidents.")
        } catch _ {
            print("Could not load incidents, DataHandler uses no incident")
        }
    }
    
    static func saveToJSON() {
        do {
            let data = try JSONEncoder().encode(incidents)
            let jsonFileWrapper = FileWrapper(regularFileWithContents: data)
            try jsonFileWrapper.write(to: Constants.localStorageURL, options: FileWrapper.WritingOptions.atomic, originalContentsURL: nil)
            print("Saved incidents!")
        } catch _ {
            print("Could not save incidents")
        }
    }
}
