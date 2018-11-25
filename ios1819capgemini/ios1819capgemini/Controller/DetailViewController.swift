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
    var incident = Incident(type: nil, description: "na")
    
    // MARK: IBOutlets
    @IBOutlet private weak var descriptionLabel: UILabel!
    
     // MARK: IBActions
    @IBAction private func backButtonPressed(_ sender: Any) {
         self.dismiss(animated: true, completion: nil)
    }

    // MARK: Overridden/Lifecycle Methods
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.modalPresentationStyle = .overCurrentContext
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        
        // add blurred subview
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = UIScreen.main.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.navigationController?.view.addSubview(blurView)
        self.navigationController?.view.sendSubviewToBack(blurView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        descriptionLabel.text = incident.description
        descriptionLabel.reloadInputViews()
    }
    
}
