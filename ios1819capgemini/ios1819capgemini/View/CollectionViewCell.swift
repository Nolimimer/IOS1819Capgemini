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
    
    @IBOutlet private weak var imageView: UIImageView!
    @IBOutlet private weak var deleteButton: UIButton!
    
    var attachment: Attachment? = nil
    weak var detailViewController: DetailViewController? = nil
    
    @IBAction func deleteAttachment(_ sender: Any) {
        guard let attachment = attachment else {
            return
        }
        detailViewController?.removeAttachment(withName: attachment.name)
    }
    
    
    func populateWithAttachment(_ attachment: Attachment, detail: DetailViewController ,isEdit: Bool) {
        self.attachment = attachment
        self.detailViewController = detail
        let attachmentWrapper = AttachmentWrapper(attachment: attachment)

        if(attachment.name == "plusButton") {
            deleteButton.isHidden = true
        }
        
        if !isEdit {
            deleteButton.isHidden = true
        } else {
            if(attachment.name != "plusButton") {
                deleteButton.isHidden = false
                self.bringSubviewToFront(deleteButton)
            }
        }
        for view in imageView.subviews {
            view.removeFromSuperview()
        }
        imageView.reloadInputViews()
        
        attachmentWrapper.loadThumbnailImage()
        self.imageView.image = nil
        guard let thumbnail = attachmentWrapper.thumbnail else {
            return
        }
        self.imageView.image = cropToBounds(image: thumbnail, width: 90, height: 88)
        if attachment is Photo {
            //imageView.transform = imageView.transform.rotated(by: CGFloat(M_PI_2))
            let image = makeRoundImg(img: self.imageView)
            self.imageView.image = image
            return
        }
        if attachment is Video {
            let frontImage = #imageLiteral(resourceName: "play5") // The image in the foreground
            let frontImageView = UIImageView(image: frontImage) // Create the view holding the image
            let xCoord = self.imageView.center.x - 30
            let yCoord = self.imageView.center.y - 30
            frontImageView.frame = CGRect(x: xCoord, y: yCoord, width: 20, height: 20)
//            let x =  (self.imageView.frame.minX - self.imageView.frame.maxX)/2
//            let y = (self.imageView.frame.minY - self.imageView.frame.maxY)/2
//            let triangle = CGRect(x: x, y: y, width: 2m0, height: 20)
            self.imageView.addSubview(frontImageView)
//            self.imageView.image = cropToBounds(image: imageView.image ?? UIImage(), width: 90, height: 88)
            let image = makeRoundImg(img: self.imageView)
            self.imageView.image = image
            return
        }
        if attachment is Audio || attachment is TextDocument {
            let image = makeRoundImg(img: self.imageView)
            self.imageView.image = image
            return
        }
    }
    
    func changeDeleteButtonVisibility(isEdit: Bool) {
        if(attachment?.name == "plusButton") ?? false {
            deleteButton.isHidden = true
        }
        
        if !isEdit {
            deleteButton.isHidden = true
        } else {
            if(attachment?.name != "plusButton") ?? false {
                deleteButton.isHidden = false
                self.bringSubviewToFront(deleteButton)
            }
        }
    }

    func makeRoundImg(img: UIImageView) -> UIImage {
        let imgLayer = CALayer()
        imgLayer.frame = img.bounds
        imgLayer.contents = img.image?.cgImage
        imgLayer.masksToBounds = true
        
        imgLayer.cornerRadius = imgLayer.frame.size.width / 2 //img.frame.size.width/2
        
        // swiftlint:disable force_unwrapping
        UIGraphicsBeginImageContext(img.bounds.size)
        imgLayer.render(in: UIGraphicsGetCurrentContext()!)
        let roundedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return roundedImage!
        // swiftlint:enable force_unwrapping
    }
    
    func cropToBounds(image: UIImage, width: Double, height: Double) -> UIImage {
        guard let imageCgImage = image.cgImage else {
            print("Error")
            return image
        }
        let cgimage = imageCgImage
        let contextImage = UIImage(cgImage: cgimage)
        let contextSize: CGSize = contextImage.size
        var posX: CGFloat = 0.0
        var posY: CGFloat = 0.0
        var cgwidth = CGFloat(width)
        var cgheight = CGFloat(height)
        
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
        
        let rect = CGRect(x: posX, y: posY, width: cgwidth, height: cgheight)
        
        // Create bitmap image from context using the rect
        guard let cgimageCropping = cgimage.cropping(to: rect) else {
            print("Error")
            return image
        }
        let imageRef: CGImage = cgimageCropping
        
        // Create a new image based on the imageRef and rotate back to the original orientation
        let image = UIImage(cgImage: imageRef, scale: image.scale, orientation: image.imageOrientation)
        
        return image
    }
}

extension UIImageView {
    func setImageColor(color: UIColor) {
        let templateImage = self.image?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        self.image = templateImage
        self.tintColor = color
    }
}
