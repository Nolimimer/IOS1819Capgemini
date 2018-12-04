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
    @IBOutlet weak var imageView: UIImageView!
}
