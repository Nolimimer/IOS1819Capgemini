//
//  DetailViewController+UIDocumentMenuDelegate.swift
//  ios1819capgemini
//
//  Created by MembrainDev on 08.01.19.
//  Copyright © 2019 TUM LS1. All rights reserved.
//

import Foundation
import UIKit
import MobileCoreServices

extension DetailViewController: UIDocumentMenuDelegate,UIDocumentPickerDelegate {


    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let myURL = url as URL
        print("import result : \(myURL)")
        if myURL.lastPathComponent.hasSuffix("pdf") {
            let paths = NSSearchPathForDirectoriesInDomains(
                FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            let documentsDirectory = URL(fileURLWithPath: paths[0])
            let defaults = UserDefaults.standard
            let name = "cARgeminiasset\(defaults.integer(forKey: "AttachedTextDocumentName")).pdf"
            let path = documentsDirectory.appendingPathComponent(name)
            defaults.set(defaults.integer(forKey: "AttachedPhotoName") + 1, forKey: "AttachedTextDocumentName")
            let data = try? Data.init(contentsOf: myURL)
            do {
                try data?.write(to: path)
                let textDocument = TextDocument(name: name, filePath: "\(paths[0])/\(name)")
                incident.addAttachment(attachment: textDocument)
                reloadCollectionView()
            } catch {
                print ("Could not save Text Document to \(path)")
            }
           
        } else {
            print("I only save pdfs")
        }
    }
    
    
    public func documentMenu(_ documentMenu:UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("view was cancelled")
        dismiss(animated: true, completion: nil)
    }
}
