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
protocol Attachment: Codable {
    static var type: AttachmentType { get }
    var data: Data? { get }
    var identifier: Int { get }
    var date: Date { get }
    var filePath: String { get set }
    var name: String { get }
    
//    do { try data = Data(contentsOf: URL(fileURLWithPath: filePath))
//    } catch {
//    data = nil
//    }
//    date = Date()
//    self.name = name
//    self.filePath = filePath
//    let defaults = UserDefaults.standard
//    identifier = defaults.integer(forKey: "AttachmentIdentifer")
//    defaults.set(defaults.integer(forKey: "AttachmentIdentifer") + 1, forKey: "AttachmentIdentifer")
//
    func computeThumbnail() -> UIImage
    
    func reevaluatePath()
}

public class AttachmentWrapper {
    let attachment: Attachment
    var thumbnail: UIImage?
    
    init (attachment: Attachment) {
        self.attachment = attachment
    }
    
    
    func loadThumbnailImage() {
        self.thumbnail = attachment.computeThumbnail()
    }

}
