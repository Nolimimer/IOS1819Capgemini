//
//  Photo.swift
//  ios1819capgemini
//
//  Created by MembrainDev on 04.12.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

import Foundation
import INSPhotoGallery

class Photo: Attachment {

    init(name: String, photoPath: String) {
        super.init(name: name, filePath: photoPath)
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
    override func computeThumbnail() -> UIImage {
        if name == "plusButton" {
            guard let result = UIImage(named: "plusbutton") else {
                return UIImage()
            }
            return result
        }
        guard let result = UIImage(contentsOfFile: filePath) else {
            return UIImage()
        }
        return result
    }
}

class PhotoWrapper: AttachmentWrapper, INSPhotoViewable {
    @objc open var image: UIImage?
    @objc open var thumbnailImage: UIImage?
    var photo: Photo
    @objc open var attributedTitle: NSAttributedString?
    
    init(photo: Photo) {
        self.photo = photo
        thumbnailImage = UIImage(contentsOfFile: photo.filePath)
        image = UIImage(contentsOfFile: photo.filePath)
        super.init(attachment: photo)
    }
    
   
    
    @objc open func loadImageWithCompletionHandler(_ completion: @escaping (_ image: UIImage?, _ error: Error?) -> ()) {
        if let image = image {
            completion(image, nil)
            return
        }
        loadImageWithURL(URL(fileURLWithPath: photo.filePath), completion: completion)
    }
    @objc open func loadThumbnailImageWithCompletionHandler(_ completion: @escaping (_ image: UIImage?, _ error: Error?) -> ()) {
        let thumbnailImage = photo.computeThumbnail()
        completion(image, nil)
    }
    
    open func loadImageWithURL(_ url: URL?, completion: @escaping (_ image: UIImage?, _ error: Error?) -> ()) {
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        if let imageURL = url {
            session.dataTask(with: imageURL, completionHandler: { (response, data, error) in
                DispatchQueue.main.async(execute: { () -> Void in
                    if error != nil {
                        completion(nil, error)
                    } else if let response = response, let image = UIImage(data: response) {
                        completion(image, nil)
                    } else {
                        completion(nil, NSError(domain: "INSPhotoDomain", code: -1, userInfo: [ NSLocalizedDescriptionKey: "Couldn't load image"]))
                    }
                    session.finishTasksAndInvalidate()
                })
            }).resume()
        } else {
            completion(nil, NSError(domain: "INSPhotoDomain", code: -2, userInfo: [ NSLocalizedDescriptionKey: "Image URL not found."]))
        }
    }
}
