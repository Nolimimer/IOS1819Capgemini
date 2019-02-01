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
        for carPart in DataHandler.carParts {
            print(carPart.name)
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
            let name = carPart.name.dropLast(".arobject".count)
            let imageURL = URL(fileURLWithPath: dirPath).appendingPathComponent("\(name).jpg")
            let image = UIImage(contentsOfFile: imageURL.path)
            cell.modelImage.image = image
            cell.incidentLabel.text = String(name)
            cell.openNumber.text = String(incidents.filter { $0.status == .open }.count)
            cell.progessNumber.text = String(incidents.filter { $0.status == .progress }.count)
            cell.resolvedNumber.text = String(incidents.filter { $0.status == .resolved }.count)
        }
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, editActionsForItemAt indexPath: IndexPath, for orientation: SwipeActionsOrientation) -> [SwipeAction]? {
        guard orientation == .right else { print("collection View error"); return nil }
        let deleteAction = SwipeAction(style: .destructive, title: "Delete") { action, indexPath in
            // handle action by updating model with deletion
//            let name = self.sortedDictonary[indexPath.item]
            let carPart = DataHandler.carParts[indexPath.item]
            let name = carPart.name
            self.removeScan(identifier: name)
//            DataHandler.objectsToIncidents.removeValue(forKey: name)
//            DataHandler.saveToJSON()
            DataHandler.carParts.removeAll(where: { $0.name == "\(name)" })
            DataHandler.saveToJSON()
        }
        // customize the action appearance
//        deleteAction.image = #imageLiteral(resourceName: "Trash Icon")
        
        return [deleteAction]
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
