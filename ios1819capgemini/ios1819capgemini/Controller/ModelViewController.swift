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
    var sortedDictonary = Array(DataHandler.objectsToIncidents.keys).sorted()
    
    func removeScan(identifier: String) {
        let fileManager = FileManager.default
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            for file in fileURLs {
                if file.absoluteString == "\(identifier).arobject" {
                    print("file absolute string: \(file.absoluteString) has been removed")
                    try fileManager.removeItem(at: file.absoluteURL)
                }
            }
        } catch {
            print("Error loading custom scans")
        }
    }
    
    @IBAction private func backButton(_ sender: Any) {
        creatingNodePossible = true
        self.dismiss(animated: false, completion: nil)
    }
    
    // MARK: Overriddent instance methods
    override func viewDidLoad() {
        super.viewDidLoad()
        ARViewController.selectedCarPart?.incidents = DataHandler.incidents
        ModelViewController.carPart = ARViewController.selectedCarPart
        DataHandler.incidents = []
        if let carPart = ModelViewController.carPart {
            if DataHandler.containsCarPart(carPart: carPart) {
                DataHandler.replaceCarPart(carPart: carPart)
            } else {
                DataHandler.setCarParts()
            }
        }
        // add blurred subview
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = UIScreen.main.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.navigationController?.view.addSubview(blurView)
        self.navigationController?.view.sendSubviewToBack(blurView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        creatingNodePossible = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ARViewController.resetButtonPressed = true
    }

    
    let reuseIdentifier = "modelCell"
    
    // MARK: - UICollectionViewDataSource protocol
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return DataHandler.objectsToIncidents.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let name = sortedDictonary[indexPath.item]
        let incidents = DataHandler.objectsToIncidents[name]
        // swiftlint:disable force_cast
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier,
                                                      for: indexPath as IndexPath) as! ARModelsCollectionViewCell
        // swiftlint:enable force_cast
        
        let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
        let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask
        let paths = NSSearchPathForDirectoriesInDomains(nsDocumentDirectory, nsUserDomainMask, true)
        if let dirPath = paths.first {
            let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent("\(name).jpg")
            let image = UIImage(contentsOfFile: imageURL.path)
            cell.modelImage.image = image
            cell.incidentLabel.text = name
            cell.openNumber.text = String(incidents?.filter { $0.status == .open }.count ?? 0)
            cell.progessNumber.text = String(incidents?.filter { $0.status == .progress }.count ?? 0)
            cell.resolvedNumber.text = String(incidents?.filter { $0.status == .resolved }.count ?? 0)
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, editActionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { print("collection View error"); return nil }
        
        print("collection view ")
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            // handle action by updating model with deletion
            print("delete action")
            let name = self.sortedDictonary[indexPath.item]
            self.removeScan(identifier: name)
            DataHandler.objectsToIncidents.removeValue(forKey: name)
            self.sortedDictonary = Array(DataHandler.objectsToIncidents.keys).sorted()
            print("DataHandler objects to incidents : \(DataHandler.objectsToIncidents)")
            print("sorted dictionary: \(self.sortedDictonary)")
            DataHandler.saveToJSON()
        }
        
        // customize the action appearance
//        deleteAction.image = #imageLiteral(resourceName: "Trash Icon")
        
        return [deleteAction]
    }
    
    
    
    
    // MARK: - UICollectionViewDelegate protocol
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // only viewing
    }
}
