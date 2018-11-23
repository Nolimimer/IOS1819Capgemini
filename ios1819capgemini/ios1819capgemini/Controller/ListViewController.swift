//
//  ListViewController.swift
//  ios1819capgemini
//
//  Created by Thomas Böhm on 19.11.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

// MARK: Imports
import UIKit

// MARK: MyClass
class ListViewController: UIViewController {

    // MARK: IBOutlets
    @IBOutlet private weak var tableView: UITableView!
    
    // MARK: Instance proprties
    let incidents = ["Scratch", "Dent"]
    
    // MARK: Overriddent instance methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.reloadData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.modalPresentationStyle = .overCurrentContext
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.view.bringSubviewToFront(tableView)
        
        // add blurred subview
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = UIScreen.main.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.navigationController?.view.addSubview(blurView)
        self.navigationController?.view.sendSubviewToBack(blurView)
    }

    // MARK: IBActions
    @IBAction private func didPressAddButton(_ sender: Any) {
         self.dismiss(animated: true, completion: nil)
    }
}

// MARK: Extension - UITableViewDelegate
extension ListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "incidentCell", for: indexPath)
        cell.textLabel?.text = incidents[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return incidents.count
    }
}
