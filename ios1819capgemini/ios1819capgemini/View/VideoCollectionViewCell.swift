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
        
        let frontImage = UIImage(named: "play")
        let frontImageView = UIImageView(image: frontImage)
        frontImageView.frame = self.imageView.frame 
        
        self.imageView.image = attachmentWrapper.thumbnail
        self.imageView.addSubview(frontImageView)
        
    }
}
