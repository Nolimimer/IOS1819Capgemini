//
//  TextDocument.swift
//  ios1819capgemini
//
//  Created by MembrainDev on 08.01.19.
//  Copyright © 2019 TUM LS1. All rights reserved.
//

import Foundation
import UIKit

class TextDocument: Attachment {
    static var type = AttachmentType.textDocument
    var data: Data?
    var identifier: Int
    var date: Date
    var filePath: String
    var name: String
    
 
    init(name: String, filePath: String) {
        do {
            try data = Data(contentsOf: URL(fileURLWithPath: filePath))
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
        let frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 120, height: 120))
        let cgImage = CIContext().createCGImage(CIImage(color: .red), from: frame)!
        let uiImage = UIImage(cgImage: cgImage)
        return uiImage
    }
}
