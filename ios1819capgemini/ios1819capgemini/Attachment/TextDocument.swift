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
 
    override init(name: String, filePath: String) {
        super.init(name: name, filePath: filePath)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override func computeThumbnail() -> UIImage {
        let frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 120, height: 120))
        let cgImage = CIContext().createCGImage(CIImage(color: .red), from: frame)!
        let uiImage = UIImage(cgImage: cgImage)
        return uiImage
    }
}
