//
//  ModelViewController.swift
//  ios1819capgemini
//
//  Created by Michael Schott on 11.01.19.
//  Copyright © 2019 TUM LS1. All rights reserved.
//

import Foundation
import UIKit

class ModelViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    let reuseIdentifier = "modelCell" 
    var items = ["1", "2", "3", "4", "5", "6"]
    
    // MARK: - UICollectionViewDataSource protocol
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        //swiftlint:disable all
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! ARModelsCollectionViewCell
        
        // Use the outlet in our custom class to get a reference to the UILabel in the cell
        cell.numberOfIncidents.text = self.items[indexPath.item]
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate protocol
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // only viewing
    }
}
