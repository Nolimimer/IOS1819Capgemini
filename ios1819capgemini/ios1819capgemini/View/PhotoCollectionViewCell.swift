//
//  PhotoCollectionViewCell.swift
//  ios1819capgemini
//
//  Created by MembrainDev on 03.12.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

import Foundation
import UIKit
import INSPhotoGallery

class ExampleCollectionViewCell: UICollectionViewCell {
    @IBOutlet private weak var imageView: UIImageView!
    
    func populateWithPhoto(_ photo: INSPhotoViewable) {
        photo.loadThumbnailImageWithCompletionHandler { [weak photo] image, _ in
            if let image = image {
                if let photo = photo as? INSPhoto {
                    photo.thumbnailImage = image
                }
                self.imageView.image = image
            }
        }
    }
}
