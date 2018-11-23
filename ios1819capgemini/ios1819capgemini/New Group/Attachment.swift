//
//  Attachment.swift
//  ios1819capgemini
//
//  Created by MembrainDev on 19.11.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

import Foundation
import UIKit

public struct Attachment: Codable {
    private var identifier: Int = 0
    private var date: Date
    private var size: Double
    private var filePath: String
    
    init(date: Date, name: String, size: Double, filePath: String) {
        self.date = date
        self.size = size
        self.filePath = filePath
        identifier = self.identifier + 1
    }
}
