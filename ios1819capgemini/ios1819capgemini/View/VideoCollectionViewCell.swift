//
//  VideoCollectionViewCell.swift
//  ios1819capgemini
//
//  Created by MembrainDev on 03.12.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

import Foundation
import UIKit

class VideoCollectionViewCell: UICollectionViewCell {
    @IBOutlet private weak var imageView: UIImageView!
    
    func populateWithVideo(_ video: Video) {
        
        let attachmentWrapper = AttachmentWrapper(attachment: video)

        attachmentWrapper.loadThumbnailImage()
        
        let frontImage = UIImage(named: "play") // The image in the foreground
        let frontImageView = UIImageView(image: frontImage) // Create the view holding the image
        frontImageView.frame = self.imageView.frame // The size and position of the front image
        
        self.imageView.image = attachmentWrapper.thumbnail
        self.imageView.addSubview(frontImageView)
        
    }
}
