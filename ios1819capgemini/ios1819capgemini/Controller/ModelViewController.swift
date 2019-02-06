//
//  ModelViewController.swift
//  ios1819capgemini
//
//  Created by Michael Schott on 11.01.19.
//  Copyright © 2019 TUM LS1. All rights reserved.
//
//swiftlint:disable all
import Foundation
import UIKit
import SwipeCellKit

class ModelViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, SwipeCollectionViewCellDelegate {
    
    static var carPart: CarPart?
    
    func removeScan(identifier: String) {
        let fileManager = FileManager.default
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            for file in fileURLs {
                if file.lastPathComponent == "\(identifier)" {
                    try fileManager.removeItem(at: file.absoluteURL)
                }
            }
        } catch {
            print("Error loading custom scans")
        }
    }
    
    static func getURLOfSavedScan() -> [URL] {
        let fileManager = FileManager.default
        let bundleURL = Bundle.main.bundleURL
        let assetURL = bundleURL.appendingPathComponent("PreviewPictures.bundle")
        let contents = try! fileManager.contentsOfDirectory(at: assetURL, includingPropertiesForKeys: [URLResourceKey.nameKey, URLResourceKey.isDirectoryKey], options: .skipsHiddenFiles)

        return contents
    }
    
    static func saveBundleToDocuments(name: String, item: URL) {
        let fileManager = FileManager.default
        do {
            if let destPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                                  .userDomainMask,
                                                                  true).first {
                let fullDestPath = URL(fileURLWithPath: destPath)
                    .appendingPathComponent(name)
                if !fileManager.fileExists(atPath: fullDestPath.path) {
                    try fileManager.copyItem(at: item, to: fullDestPath)
                }
            }
        } catch {
        }
    }
    
    static func saveBundleToDocuments() {
        let urls = ModelViewController.getURLOfSavedScan()
        ModelViewController.getURLOfScan(name: "dashboard.jpg",urls: urls)
        ModelViewController.getURLOfScan(name: "mi_becher.jpg",urls: urls)
    }
    
    static func printDocumentsDirectory() {
        let fileManager = FileManager.default
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            for file in fileURLs {
                print("file : \(file.lastPathComponent)")
            }
        } catch {
        }
    }
    
    static func getURLOfScan(name: String, urls: [URL]) {
        for item in urls {
            if item.lastPathComponent == name {
                ModelViewController.saveBundleToDocuments(name: name, item: item)
            }
        }
    }
    
    func loadBundleToDocuments() {
        let fileManager = FileManager.default
        do {
            try fileManager.copyfileToUserDocumentDirectory(forResource: "dashboard", ofType: "jpg")
            try fileManager.copyfileToUserDocumentDirectory(forResource: "mi_becher", ofType: "jpg")
        } catch {
            print("copying dashboard and/or mi_becher failed")
        }
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            for file in fileURLs {
                print("file : \(file.lastPathComponent)")
            }
        } catch {
            print("Error loading custom scans")
        }
    }
    
    
    @IBAction private func backButton(_ sender: Any) {
        creatingNodePossible = true
        ARViewController.allowRendering = true
        self.dismiss(animated: false, completion: nil)
    }
    
    // MARK: Overriddent instance methods
    override func viewDidLoad() {
        super.viewDidLoad()
        ModelViewController.saveBundleToDocuments()
        ARViewController.allowRendering = false
        DataHandler.saveCarPart()
        // add blurred subview
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = UIScreen.main.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.navigationController?.view.addSubview(blurView)
        self.navigationController?.view.sendSubviewToBack(blurView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ARViewController.resetButtonPressed = true
        creatingNodePossible = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ARViewController.allowRendering = true
    }

    
    let reuseIdentifier = "modelCell"
    
    // MARK: - UICollectionViewDataSource protocol
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return DataHandler.carParts.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let carPart = DataHandler.carParts[indexPath.row]
        let incidents = carPart.incidents
        // swiftlint:disable force_cast
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                                      for: indexPath as IndexPath) as! ARModelsCollectionViewCell
        // swiftlint:enable force_cast
        
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        if let dirPath = paths.first {
            let name = carPart.name.dropLast(".arobject".count).lowercased()
            let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent("\(name).jpg")
            //fuck this shit
            if name == "dashboard" {
                let image = UIImage(named: "dashboard")
                cell.modelImage.image = image
            }
            else if name == "mi_becher" {
                let image = UIImage(named: "becher")
                cell.modelImage.image = image
            } else {
                let image = UIImage(contentsOfFile: imageURL.path)
                cell.modelImage.image = image
            }
            cell.incidentLabel.text = String(name)
            cell.openNumber.text = String(incidents.filter { $0.status == .open }.count)
            cell.progessNumber.text = String(incidents.filter { $0.status == .progress }.count)
            cell.resolvedNumber.text = String(incidents.filter { $0.status == .resolved }.count)
        }
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, editActionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { return nil }
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            let carPart = DataHandler.carParts[indexPath.item]
            let name = carPart.name
            self.removeScan(identifier: name)
            DataHandler.carParts.removeAll(where: { $0.name == "\(name)" })
            DataHandler.saveToJSON()
        }
        let shareAction = SwipeAction(style: .default, title: "Share") { action, indexPath in
            let carPart = DataHandler.carParts[indexPath.item]
            DataHandler.saveToJSON(carPart: carPart)
            let data = DataHandler.getJSONCurrentCarPart()
            
            guard let data = data else { print("dumm gelaufen") return }
            let activityController = UIActivityViewController(activityItems: [data], applicationActivities: nil)
            
            let excludedActivities =
                [UIActivity.ActivityType.mail,
                 UIActivity.ActivityType.addToReadingList,
                 UIActivity.ActivityType.assignToContact,
                 UIActivity.ActivityType.copyToPasteboard,
                 UIActivity.ActivityType.postToTencentWeibo,
                 UIActivity.ActivityType.postToFacebook,
                 UIActivity.ActivityType.postToTwitter,
                 UIActivity.ActivityType.postToFlickr,
                 UIActivity.ActivityType.postToWeibo,
                 UIActivity.ActivityType.postToVimeo]
            
            activityController.excludedActivityTypes = excludedActivities
            self.present(activityController, animated: true, completion: nil)
        }
        shareAction.backgroundColor = UIColor.orange
        
        return [deleteAction, shareAction]
    }
    
    func collectionView(_ collectionView: UICollectionView, editActionsOptionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> SwipeOptions {
        var options = SwipeOptions()
        options.expansionStyle = .destructiveAfterFill
        options.transitionStyle = .border
        return options
    }
    
    // MARK: - UICollectionViewDelegate protocol
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // only viewing
    }
}

extension FileManager {
    func copyfileToUserDocumentDirectory(forResource name: String,
                                         ofType ext: String) throws {
        if let bundlePath = Bundle.main.path(forResource: name, ofType: ext),
            let destPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,
                                                               .userDomainMask,
                                                               true).first {
            let fileName = "\(name).\(ext)"
            let fullDestPath = URL(fileURLWithPath: destPath)
                .appendingPathComponent(fileName)
            let fullDestPathString = fullDestPath.path
            
            if !self.fileExists(atPath: fullDestPathString) {
                try self.copyItem(atPath: bundlePath, toPath: fullDestPathString)
            }
        }
    }
}
