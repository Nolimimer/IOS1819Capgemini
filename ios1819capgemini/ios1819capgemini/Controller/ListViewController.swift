//
//  ListViewController.swift
//  ios1819capgemini
//
//  Created by Thomas Böhm on 19.11.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

// MARK: Imports
import UIKit

// MARK: LastViewController
class ListViewController: UIViewController {

    // MARK: IBOutlets
    @IBOutlet private weak var tableView: UITableView!
    
    // MARK: Overridden/Lifecycle Methods
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigationController = segue.destination as? UINavigationController {
            guard let detailsViewController = navigationController.viewControllers.first as? DetailViewController,
                let senderCell = sender as? UITableViewCell,
                let incident = DataHandler.incident(withId: senderCell.tag) else {
                        print("Unknown Sender in segue to DetailViewController")
                        return
                }
                detailsViewController.incident = incident
            }
    }


    // MARK: Overriddent instance methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // add blurred subview
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = UIScreen.main.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.navigationController?.view.addSubview(blurView)
        self.navigationController?.view.sendSubviewToBack(blurView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        DataHandler.refreshOpenIncidents()
        tableView.reloadData()
        super.viewWillAppear(animated)
        self.modalPresentationStyle = .overCurrentContext
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.view.bringSubviewToFront(tableView)
    }

    // MARK: IBActions
    @IBAction private func didPressAddButton(_ sender: Any) {
         self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction private func shareButtonPressed(_ sender: Any) {
        share()
    }
    
    @IBAction private func showButton(_ sender: UIBarButtonItem) {
        if DataHandler.showAll == false {
            // In show open state
            DataHandler.showAll = true
            sender.title = "Show Open"
            DataHandler.refreshOpenIncidents()
            tableView.reloadData()
        } else {
            // In filter list state
            sender.title = "Show All"
            DataHandler.showAll = false
            DataHandler.refreshOpenIncidents()
            tableView.reloadData()
        }
    }
    // Share with airDrop just works on iPhone and not in the xCode simulator
  
    
    private func share() {
    let activityController = UIActivityViewController(activityItems: DataHandler.incidents, applicationActivities: nil)
        
        let excludedActivities =
            [UIActivity.ActivityType.mail,
             UIActivity.ActivityType.addToReadingList,
             UIActivity.ActivityType.assignToContact,
             UIActivity.ActivityType.copyToPasteboard,
             UIActivity.ActivityType.mail,
             UIActivity.ActivityType.postToTencentWeibo,
             UIActivity.ActivityType.postToFacebook,
             UIActivity.ActivityType.postToTwitter,
             UIActivity.ActivityType.postToFlickr,
             UIActivity.ActivityType.postToWeibo,
             UIActivity.ActivityType.postToVimeo]
        
        activityController.excludedActivityTypes = excludedActivities
        
        present(activityController, animated: true, completion: nil)
    
    }
    
    private func receive() {
        
    }
    
    
}

// MARK: Extension - UITableViewDelegate
extension ListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if DataHandler.showAll == true { // In show all incidents state
            let cell = tableView.dequeueReusableCell(withIdentifier: "incidentCell", for: indexPath)
            let incident = DataHandler.incidents[indexPath.row]
            cell.textLabel?.text = "\(incident.type.rawValue) \(incident.identifier)"
            cell.tag = incident.identifier
            cell.detailTextLabel?.text = incident.description
            return cell
        } else { // In open incidents state
            let cell = tableView.dequeueReusableCell(withIdentifier: "incidentCell", for: indexPath)
            let openIncident = DataHandler.openIncidents[indexPath.row]
            cell.textLabel?.text = "\(openIncident.type.rawValue) \(openIncident.identifier)"
            cell.tag = openIncident.identifier
            cell.detailTextLabel?.text = openIncident.description
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
       if DataHandler.showAll == true {
            return DataHandler.incidents.count
       } else {
            return DataHandler.openIncidents.count
        }
    }
}
