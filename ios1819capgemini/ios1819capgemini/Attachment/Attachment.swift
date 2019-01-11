//
//  Attachment.swift
//  ios1819capgemini
//
//  Created by MembrainDev on 19.11.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

// MARK: Imports
import Foundation
import UIKit
import AVKit

// MARK: - Attachment
public class Attachment: Codable {
    
    let data: Data?
    private let identifier: Int
    private(set) var date: Date
    private(set) var filePath: String
    private(set) var name: String
    
    // MARK: Initializers
    init(name: String, filePath: String) {
        do { try data = Data(contentsOf: URL(fileURLWithPath: filePath))
        } catch {
            data = nil
        }        
        date = Date()
        self.name = name
        self.filePath = filePath
        let defaults = UserDefaults.standard
        identifier = defaults.integer(forKey: "AttachmentIdentifer")
        defaults.set(defaults.integer(forKey: "AttachmentIdentifer") + 1, forKey: "AttachmentIdentifer")
    }
    
    func computeThumbnail() -> UIImage {
        print("Should be implemented by subclass")
        return UIImage()
    }
}

public class AttachmentWrapper {
    let attachment: Attachment
    var thumbnail: UIImage?
    
    init (attachment: Attachment) {
        self.attachment = attachment
    }
    
    
    func loadThumbnailImage() -> Void {
        self.thumbnail = attachment.computeThumbnail()
    }

}
