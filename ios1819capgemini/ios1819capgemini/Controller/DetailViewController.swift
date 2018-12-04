//
//  DetailViewController.swift
//  ios1819capgemini
//
//  Created by Thomas Böhm on 19.11.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

// MARK: Imports
import UIKit
import SceneKit

// MARK: - DetailViewController
class DetailViewController: UIViewController {
    
    private var modus = Modus.view
    
    private var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
        return dateFormatter
    }
    
    // Variables / Mock Variable
    var incident = Incident(type: IncidentType.dent,
                            description: "This scratch is a critical one, my suggestion is to completly remove the right door.",
                            coordinate: Coordinate (vector: SCNVector3(0, 0, 0)))
    
    // MARK: IBOutlets
    @IBOutlet private weak var navigationItemIncidentTitle: UINavigationItem!
    @IBOutlet private weak var generatedDateLabel: UILabel!
    @IBOutlet private weak var lastModifiedDateLabel: UILabel!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var segmentControll: UISegmentedControl!
    @IBOutlet private weak var backButton: UIBarButtonItem!
    @IBOutlet private weak var textField: UITextView!
    @IBOutlet private weak var editButton: UIBarButtonItem!
    
    // MARK: IBActions
    @IBAction private func backButtonPressed(_ sender: Any) {
         self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func editButtonPressed(_ sender: Any) {
        switch modus {
        case .view:
            editButton.title = "Save"
            textField.isEditable = true
            segmentControll.isEnabled = true
            textField.layer.borderWidth = 1.0
            textField.layer.borderColor = UIColor.white.cgColor
            
            modus = .edit
        case .edit:
            // Saves changes
            var status: Status
            switch segmentControll.selectedSegmentIndex {
            case 0:
                status = .open
            case 1:
                status = .progress
            default:
                status = .resolved
            }
            incident.edit(status: status, description: textField.text, modifiedDate: Date())
            
            editButton.title = "Edit"
            textField.isEditable = false
            segmentControll.isEnabled = false
            textField.layer.borderWidth = 0.0
            lastModifiedDateLabel.text = dateFormatter.string(from: incident.modifiedDate)
            
            modus = .view
        }
    }
   
    // MARK: Overridden/Lifecycle Methods
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        modalPresentationStyle = .overCurrentContext
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        
        navigationItemIncidentTitle.title = "\(incident.type.rawValue) \(incident.identifier)"
        
        let controllIndex: Int
        switch incident.status {
        case .open:
            controllIndex = 0
        case .progress:
            controllIndex = 1
        case .resolved:
            controllIndex = 2
        }
        segmentControll.selectedSegmentIndex = controllIndex
        
        let dateString = dateFormatter.string(from: incident.createDate)
        let lastModifiedDateString = dateFormatter.string(from: incident.modifiedDate)
        generatedDateLabel.text = dateString
        lastModifiedDateLabel.text = lastModifiedDateString
        textField.text = incident.description
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add blurred subview
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = UIScreen.main.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.navigationController?.view.addSubview(blurView)
        self.navigationController?.view.sendSubviewToBack(blurView)
    }
    
}

// MARK: Extension
extension DetailViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "attachmentCell", for: indexPath) as? CollectionViewCell
        // Just for testing/mocking // TODO
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

// MARK: Constants
enum Modus {
    case view
    case edit
}
