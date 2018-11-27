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

// MARK: - Attachment
public struct Attachment: Codable {
    private static var identifier: Int = 0
    private var date: Date
    private var size: Double
    private var filePath: String
    
    // MARK: Initializers
    init(name: String, size: Double, filePath: String) {
        date = Date()
        self.size = size
        self.filePath = filePath
        Attachment.identifier += 1
    }
    
}
