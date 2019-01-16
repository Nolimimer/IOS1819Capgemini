//
//  ARViewControllerScreenshot.swift
//  ios1819capgemini
//
//  Created by Minh Tran on 29.12.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

import Foundation
import UIKit

extension ARViewController {

    // MARK: screenshot methods
    func saveImage(image: UIImage, incident: Incident) {
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        let paths = NSSearchPathForDirectoriesInDomains(
            FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentsDirectory = URL(fileURLWithPath: paths[0])
        
        guard let data = image.jpegData(compressionQuality: 0.5) else {
            return
        }
        do {
            let defaults = UserDefaults.standard
            let name = "cARgeminiasset\(defaults.integer(forKey: "AttachedPhotoName")).jpg"
            let path = documentsDirectory.appendingPathComponent(name)
            try data.write(to: path, options: [])
            defaults.set(defaults.integer(forKey: "AttachedPhotoName") + 1, forKey: "AttachedPhotoName")
            incident.addAttachment(attachment: Photo(name: name, photoPath: "\(paths[0])/\(name)"))
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    // Temporarily deletes all the pins except for the pin in the method call from the view and then adds them back again after 1 second
    func filter3DPins (identifier: String) {
        
        self.scene.rootNode.childNodes.forEach { node in
            guard let name = node.name else {
                return
            }
            if name != identifier && name != "info-plane"{
                let tmpNode = node
                self.scene.rootNode.childNode(withName: name, recursively: false)?.removeFromParentNode()
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                    self.scene.rootNode.addChildNode(tmpNode)
                })
            }
        }
    }
    // Temporarily deletes all the pins from the view and then adds them back again after 1 second
    func filterAllPins () {
        
        self.scene.rootNode.childNodes.forEach { node in
            guard let name = node.name else {
                return
            }
            
            let tmpNode = node
            if node.name != "info-plane" {
                self.scene.rootNode.childNode(withName: name, recursively: false)?.removeFromParentNode()
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                    self.scene.rootNode.addChildNode(tmpNode)
                })
            }

        }
    }
}
