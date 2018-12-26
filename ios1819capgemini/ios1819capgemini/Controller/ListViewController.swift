//
//  ListViewController.swift
//  ios1819capgemini
//
//  Created by Thomas Böhm on 19.11.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

// MARK: Imports
import UIKit
//swiftlint:disable all
// MARK: LastViewController
class ListViewController: UIViewController {
    
    private var showOpen = true
    private var showInProgress = false
    private var showAll = false

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
        if showOpen {
            sender.title = "Show All"
            showAll = true
            showOpen = false
            tableView.reloadData()
        }
        else if showAll {
            sender.title = "Show in Progress"
            showInProgress = true
            showAll = false
            tableView.reloadData()
        }
        else if showInProgress {
            sender.title = "Show Open"
            showOpen = true
            showInProgress = false
            tableView.reloadData()
        }
    }
  
    
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "incidentCell", for: indexPath)
        var incidents : [Incident]
        if showOpen {
            incidents = DataHandler.incidents.filter( {$0.status == .open})
        }
        else if showInProgress {
            incidents = DataHandler.incidents.filter( {$0.status == .progress})
        }
        else {
            incidents = DataHandler.incidents
        }
        let incident = incidents[indexPath.row]
        cell.textLabel?.text = incident.description
        cell.tag = incident.identifier
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        var incidents: [Incident]
        if showOpen {
            incidents = DataHandler.incidents.filter( {$0.status == .open})
        }
        else if showInProgress {
            incidents = DataHandler.incidents.filter( {$0.status == .progress})
        }
        else {
            incidents = DataHandler.incidents
        }
        return incidents.count
    }
}
