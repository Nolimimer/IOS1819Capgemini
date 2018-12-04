//
//  CollectionViewCell.swift
//  ios1819capgemini
//
//  Created by Michael Schott on 30.11.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

// MARK: Imports
import UIKit

// MARK: - CollectionViewCell
class CollectionViewCell: UICollectionViewCell {
    
    // Nicht private!
    // Diese Cell muss von DetailViewController
    // aufgerufen werden, um die Funktionalität
    // in diese Klasse zu delegieren.
    @IBOutlet private weak var imageView: UIImageView!
    
    func populateWithAttachment(_ attachment: Attachment) {
        
        let attachmentWrapper = AttachmentWrapper(attachment: attachment)
        
        attachmentWrapper.loadThumbnailImage()
        self.imageView.image = cropToBounds(image: attachmentWrapper.thumbnail!, width: 90, height: 88)
        if attachment is Video {
            let frontImage = UIImage(named: "play2") // The image in the foreground
            let frontImageView = UIImageView(image: frontImage) // Create the view holding the image
            frontImageView.frame = self.imageView.frame // The size and position of the front image
            self.imageView.addSubview(frontImageView)
            self.imageView.image = cropToBounds(image: imageView.image ?? UIImage(), width: 90, height: 88)
        }
        let image = makeRoundImg(img: self.imageView)
        self.imageView.image = image
       
    }

    func makeRoundImg(img: UIImageView) -> UIImage {
        let imgLayer = CALayer()
        imgLayer.frame = img.bounds
        imgLayer.contents = img.image?.cgImage
        imgLayer.masksToBounds = true
        
        imgLayer.cornerRadius = imgLayer.frame.size.width/2 //img.frame.size.width/2
        
        UIGraphicsBeginImageContext(img.bounds.size)
        imgLayer.render(in: UIGraphicsGetCurrentContext()!)
        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return roundedImage!
    }
    
    func cropToBounds(image: UIImage, width: Double, height: Double) -> UIImage {
        
        let cgimage = image.cgImage!
        let contextImage: UIImage = UIImage(cgImage: cgimage)
        let contextSize: CGSize = contextImage.size
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth: CGFloat = CGFloat(width)
        var cgheight: CGFloat = CGFloat(height)
        
        // See what size is longer and create the center off of that
        if contextSize.width > contextSize.height {
            posX = ((contextSize.width - contextSize.height) / 2)
            posY = 0
            cgwidth = contextSize.height
            cgheight = contextSize.height
        } else {
            posX = 0
            posY = ((contextSize.height - contextSize.width) / 2)
            cgwidth = contextSize.width
            cgheight = contextSize.width
        }
        
        let rect: CGRect = CGRect(x: posX, y: posY, width: cgwidth, height: cgheight)
        
        // Create bitmap image from context using the rect
        let imageRef: CGImage = cgimage.cropping(to: rect)!
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let image: UIImage = UIImage(cgImage: imageRef, scale: image.scale, orientation: image.imageOrientation)
        
        return image
    }


    
}
