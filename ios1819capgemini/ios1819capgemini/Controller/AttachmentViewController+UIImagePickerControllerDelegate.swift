//
//  AttachmentViewController+UIImagePickerControllerDelegate.swift
//  ios1819capgemini
//
//  Created by MembrainDev on 03.12.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

import Foundation
import UIKit

extension AttachmentViewController: UIImagePickerControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        if let selectedImage = info[.originalImage] as? UIImage {
            if saveImage(image: selectedImage) {
                print("Saved image")
            }
        }
        
        if let selectedVideo: URL = (info[UIImagePickerController.InfoKey.mediaURL] as? URL) {
            // Save video to the main photo album
            let selectorToCall = #selector(AttachmentViewController.videoSaved(_:didFinishSavingWithError:context:))
            
            // 2
            UISaveVideoAtPathToSavedPhotosAlbum(selectedVideo.relativePath, self, selectorToCall, nil)
            // Save the video to the app directory
            let videoData = try? Data(contentsOf: selectedVideo)
            let paths = NSSearchPathForDirectoriesInDomains(
                FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            let documentsDirectory = URL(fileURLWithPath: paths[0])
            let defaults = UserDefaults.standard
            let dataPath = documentsDirectory.appendingPathComponent("cARgeminiVideoAsset\(defaults.integer(forKey: "AttachedVideoName")).mov")
            defaults.set(defaults.integer(forKey: "AttachedVideoName") + 1, forKey: "AttachedVideoName")
            do {
                try videoData?.write(to: dataPath, options: [])
            } catch {
                print(Error.self)
            }
        }
    }
    
    func saveImage(image: UIImage) -> Bool {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        
        let paths = NSSearchPathForDirectoriesInDomains(
            FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentsDirectory = URL(fileURLWithPath: paths[0])
        
        guard let data = image.jpegData(compressionQuality: 0.5) else {
            return false
        }
        do {
            let defaults = UserDefaults.standard
            try data.write(to: documentsDirectory.appendingPathComponent("cARgeminiasset\(defaults.integer(forKey: "AttachedPhotoName")).jpg"), options: [])
            defaults.set(defaults.integer(forKey: "AttachedPhotoName") + 1, forKey: "AttachedPhotoName")
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
}
