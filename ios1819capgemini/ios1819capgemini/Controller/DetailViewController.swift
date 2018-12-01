//
//  DetailViewController.swift
//  ios1819capgemini
//
//  Created by Thomas Böhm on 19.11.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

// MARK: Imports
import UIKit

// MARK: - DetailViewController
class DetailViewController: UIViewController {

    @IBOutlet private weak var generatedDateLabel: UILabel!
    
    @IBOutlet private weak var lastModifiedDateLabel: UILabel!
    
    @IBOutlet private weak var collectionView: UICollectionView!
    
    @IBOutlet private weak var segmentControll: UISegmentedControl!
    
    @IBOutlet private weak var backButton: UIBarButtonItem!
    
    @IBOutlet private weak var textField: UITextView!
    
    @IBOutlet private weak var editButton: UIBarButtonItem!
    
    
    @IBAction private func editButtonPressed(_ sender: Any) {
        switch modus {
        case .view:
        modus = .edit
        editButton.title = "Save"
        segmentControll.isEnabled = true
            textField.isEditable = true
            textField.isSelectable = true
        case .edit:
            // TODO: change last modified in Incident
        // change last modifiered
        modus = .view
        editButton.title = "Edit"
        segmentControll.isEnabled = false
            textField.isEditable = false
            textField.isSelectable = false
        }
    }
    
    var modus = Modus.view
    
    // Variables
    var incident = Incident(type: IncidentType.dent,
                            description: "",
                            coordinate: Coordinate (pointX: 0, pointY: 0, pointZ: 0))
    
    // MARK: IBOutlets
    
    @IBOutlet private weak var navigationItemIncidentTitle: UINavigationItem!
    
    // MARK: IBActions
    @IBAction private func backButtonPressed(_ sender: Any) {
         self.dismiss(animated: true, completion: nil)
    }
   
    // MARK: Overridden/Lifecycle Methods
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.modalPresentationStyle = .overCurrentContext
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
                
        if let type = incident.type {
            navigationItemIncidentTitle.title = "\(type.rawValue) 00\(incident.identifier)"
        } else {
            navigationItemIncidentTitle.title = "Incident \(incident.identifier)"
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // TODO: handle generatedDate and modified in Incidents
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
        
       let dateString = dateFormatter.string(from: Date())
        
        generatedDateLabel.text = dateString
        
        lastModifiedDateLabel.text = dateString
        
        // add blurred subview
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = UIScreen.main.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.navigationController?.view.addSubview(blurView)
        self.navigationController?.view.sendSubviewToBack(blurView)
    }
    
}

extension DetailViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "attachmentCell", for: indexPath) as? CollectionViewCell
        // Just for testing/mocking
        // TODO
        let number = Int.random(in: 0 ..< 10)
        if number > 6 {
        cell?.imageView.image = #imageLiteral(resourceName: "picturePreview")
        } else if number > 3 {
        cell?.imageView.image = #imageLiteral(resourceName: "documentPreview")
        } else {
        cell?.imageView.image = #imageLiteral(resourceName: "videoPreview")
        }
        return cell!
    }
    
    
}

enum Modus {
    case view
    case edit
}
