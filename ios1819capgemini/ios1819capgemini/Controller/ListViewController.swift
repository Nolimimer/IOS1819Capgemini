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
    @IBOutlet private weak var filterSegmentedControl: UISegmentedControl!
    
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
        DataHandler.refreshInProgressIncidents()
        DataHandler.refreshOpenIncidents()
        filterSegmentedControl.selectedSegmentIndex = DataHandler.currentSegmentFilter
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
    
    
    @IBAction private func selectedFilterSegment(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case Filter.showAll.rawValue: // All tab
            DataHandler.currentSegmentFilter = Filter.showAll.rawValue
            tableView.reloadData()
        case Filter.showOpen.rawValue: // Open tab
            DataHandler.currentSegmentFilter = Filter.showOpen.rawValue
            DataHandler.refreshOpenIncidents()
            tableView.reloadData()
        case Filter.showInProgress.rawValue: // In Progress tab
            DataHandler.currentSegmentFilter = Filter.showInProgress.rawValue
            DataHandler.refreshInProgressIncidents()
            tableView.reloadData()
        default:
            break
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

// MARK: Segmented Filter Constants
enum Filter: Int { // Remark: Need to match Segment in Story Board.
    case showAll = 0
    case showOpen
    case showInProgress
}

// MARK: Extension - UITableViewDelegate
extension ListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "incidentCell", for: indexPath)
        let incident: Incident
        switch filterSegmentedControl.selectedSegmentIndex {
        case Filter.showAll.rawValue: // Filter by All Incidents.
            incident = DataHandler.incidents[indexPath.row]
        case Filter.showOpen.rawValue: // Filter by Open Incidents
            incident = DataHandler.openIncidents[indexPath.row]
        case Filter.showInProgress.rawValue: // Filter by In Progress Incidents
            incident = DataHandler.inProgressIncidents[indexPath.row]
        default: // Default by All Incidents.
            incident = DataHandler.incidents[indexPath.row]
        }
        cell.textLabel?.text = "\(incident.type.rawValue) \(incident.identifier)"
        cell.tag = incident.identifier
        cell.detailTextLabel?.text = incident.description
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch filterSegmentedControl.selectedSegmentIndex {
        case Filter.showAll.rawValue: // Filter by All Incidents.
            return DataHandler.incidents.count
        case Filter.showOpen.rawValue: // Filter by Open Incidents
            return DataHandler.openIncidents.count
        case Filter.showInProgress.rawValue: // Filter by In Progress Incidents
            return DataHandler.inProgressIncidents.count
        default: // Default by All Incidents.
            return DataHandler.incidents.count
        }
    }
}
