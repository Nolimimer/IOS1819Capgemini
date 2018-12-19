//
//  Audio.swift
//  ios1819capgemini
//
//  Created by MembrainDev on 19.12.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

import Foundation

class Audio: Attachment {
    
    override init(name: String, filePath: String) {
        super.init(name: name, filePath: filePath)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
