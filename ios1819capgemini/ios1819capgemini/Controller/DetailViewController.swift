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
    
    // Variables
    var incident = Incident(type: IncidentType.dent,
                            description: "",
                            coordinate: Coordinate (pointX: 0, pointY: 0, pointZ: 0))
    
    // MARK: IBOutlets

    @IBOutlet private weak var incidentTypeTextField: UITextField!
    @IBOutlet private weak var descriptionTextField: UITextField!
    
    @IBOutlet private weak var navigationItemIncidentTitle: UINavigationItem!
    
    // MARK: IBActions
    @IBAction private func backButtonPressed(_ sender: Any) {
         self.dismiss(animated: true, completion: nil)
    }
    @IBAction private func saveIncidentDetailsButtonPressed(_ sender: Any) {
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
        
        // add blurred subview
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = UIScreen.main.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.navigationController?.view.addSubview(blurView)
        self.navigationController?.view.sendSubviewToBack(blurView)
        descriptionTextField.text = incident.description
        descriptionTextField.reloadInputViews()
    }
    
}
