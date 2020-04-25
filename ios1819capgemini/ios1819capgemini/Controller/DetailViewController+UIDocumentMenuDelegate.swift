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

extension DetailViewController: UIDocumentMenuDelegate, UIDocumentPickerDelegate {

    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentAt url: URL) {
        let myURL = url as URL
        print("import result : \(myURL)")
        if myURL.lastPathComponent.hasSuffix("pdf") {
            let paths = NSSearchPathForDirectoriesInDomains(
                FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            let documentsDirectory = URL(fileURLWithPath: paths[0])
            let name = String(myURL.lastPathComponent)
            let path = documentsDirectory.appendingPathComponent(name)
            let data = try? Data.init(contentsOf: myURL)
            do {
                try data?.write(to: path)
                let textDocument = TextDocument(name: name, filePath: "\(paths[0])/\(name)")
                guard let incident = incident else {
                    print("incident not initialized document picker")
                    return
                }
                incident.addAttachment(attachment: textDocument)
                reloadCollectionView()
                hidePopup()
            } catch {
                print ("Could not save Text Document to \(path)")
            }
           
        } else {
            print("I only save pdfs")
        }
        hidePopup()
    }
    
    
    public func documentMenu(_ documentMenu: UIDocumentMenuViewController, didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        print("view was cancelled")
        dismiss(animated: true, completion: nil)
    }
}

