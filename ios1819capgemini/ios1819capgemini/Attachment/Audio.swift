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
    static var type = AttachmentType.audio
    
    var data: Data?
    var identifier: Int
    var date: Date
    var filePath: String
    var name: String
    
    
    let duration: TimeInterval
    
    init(name: String, filePath: String, duration: TimeInterval) {
        self.duration = duration
        date = Date()
        self.name = name
        data = try? Data(contentsOf: URL(fileURLWithPath: filePath))

        self.filePath = filePath
        let defaults = UserDefaults.standard
        identifier = defaults.integer(forKey: "AttachmentIdentifer")
        defaults.set(defaults.integer(forKey: "AttachmentIdentifer") + 1, forKey: "AttachmentIdentifer")
        do {
            let paths = NSSearchPathForDirectoriesInDomains(
                FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            let documentsDirectory = URL(fileURLWithPath: paths[0])
            
            let path = documentsDirectory.appendingPathComponent(name)
            guard let data = data else {
                return
            }
            try data.write(to: path, options: [])
            self.filePath = "\(paths[0])/\(name)"
            print(filePath)
        } catch {
            data = nil
        }
    }
    
    func computeThumbnail() -> UIImage {
        let frame = CGRect(origin: CGPoint(x: 0, y: 0), size: CGSize(width: 120, height: 120))
        // swiftlint:disable force_unwrapping
        let cgImage = CIContext().createCGImage(CIImage(color: .black), from: frame)!
        // swiftlint:enable force_unwrapping
        let uiImage = UIImage(cgImage: cgImage)
        return uiImage
    }
    
    func reevaluatePath() {
        do {
            let paths = NSSearchPathForDirectoriesInDomains(
                FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            let documentsDirectory = URL(fileURLWithPath: paths[0])
            let path = documentsDirectory.appendingPathComponent(name)
            guard let data = data else {
                return
            }
            try data.write(to: path, options: [])
            filePath = "\(paths[0])/\(name)"
        } catch {
            data = nil
        }
    }
}
