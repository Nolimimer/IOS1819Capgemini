//
//  Audio.swift
//  ios1819capgemini
//
//  Created by MembrainDev on 19.12.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

import Foundation
import UIKit

class Audio: Attachment {
    
    let duration: TimeInterval
    
    init(name: String, filePath: String, duration: TimeInterval) {
        self.duration = duration
        super.init(name: name, filePath: filePath)
    }
    
    required init(from decoder: Decoder) throws {
        duration = 0.0
        try super.init(from: decoder)
    }
    
    override func computeThumbnail() -> UIImage {
        let frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 120, height: 120))
        let cgImage = CIContext().createCGImage(CIImage(color: .black), from: frame)!
        let uiImage = UIImage(cgImage: cgImage)
        return uiImage
    }
}
