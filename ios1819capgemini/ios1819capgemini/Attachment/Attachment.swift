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
    private let identifier: Int
    private(set) var date: Date
    private(set) var filePath: String
    private(set) var name: String
    
    // MARK: Initializers
    init(name: String, filePath: String) {
        date = Date()
        self.name = name
        self.filePath = filePath
        let defaults = UserDefaults.standard
        identifier = defaults.integer(forKey: "AttachmentIdentifer")
        defaults.set(defaults.integer(forKey: "AttachmentIdentifer") + 1, forKey: "AttachmentIdentifer")
    }
}

public class AttachmentWrapper {
    let attachment: Attachment
    var thumbnail: UIImage?
    
    init (attachment: Attachment) {
        self.attachment = attachment
    }
    
    static func computeThumbnailImage (for attachment: Attachment) -> UIImage {
        if attachment is Video {
            guard let createdThumbnail = createThumbnailOfVideoFromRemoteUrl(url: attachment.filePath) else {
                guard let result = UIImage(named: "videoPreview") else {
                    return UIImage()
                }
                return result
            }
            return createdThumbnail
        }
        if attachment is Photo {
            if attachment.name == "plusButton" {
                guard let result = UIImage(named: "plusbutton") else {
                    return UIImage()
                }
                return result
            }
            guard let photo = attachment as? Photo else {
                return UIImage()
            }
            guard let result = UIImage(contentsOfFile: photo.filePath) else {
                return UIImage()
            }
            return result
        }
        if let result = UIImage(named: "picturePreview") {
            return result
        }
        return UIImage()
        
    }
    
    private static func createThumbnailOfVideoFromRemoteUrl(url: String) -> UIImage? {
        
        let asset = AVURLAsset(url: URL(fileURLWithPath: url), options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        
        
        //Can set this to improve performance if target size is known before hand
        //assetImgGenerate.maximumSize = CGSize(width,height)
        do {
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            return thumbnail
        } catch {
            print(error)
            return nil
        }
    }
    
    
    func loadThumbnailImage() -> Void {
        self.thumbnail = AttachmentWrapper.computeThumbnailImage(for: attachment)
    }

}
