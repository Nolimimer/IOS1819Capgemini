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

// MARK: CustomCell IBOutlets
class CustomCell: UITableViewCell {
    @IBOutlet weak var incidentTitleLabel: UILabel!
    @IBOutlet weak var incidentDescriptionLabel: UILabel!
    @IBOutlet weak var incidentNumberOfPhotos: UILabel!
    @IBOutlet weak var incidentNumberOfVideos: UILabel!
}

// MARK: ListViewController
class ListViewController: UIViewController {
    
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
        DataHandler.refreshOpenIncidents()
        DataHandler.refreshInProgressIncidents()
        DataHandler.refreshResolvedIncidents()
        filterSegmentedControl.selectedSegmentIndex = DataHandler.currentSegmentFilter
        tableView.reloadData()
        creatingNodePossible = false
        super.viewWillAppear(animated)
        self.modalPresentationStyle = .overCurrentContext
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.view.bringSubviewToFront(tableView)
    }

    // MARK: IBActions
    @IBAction private func didPressAddButton(_ sender: Any) {
         creatingNodePossible = true
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
        case Filter.showResolved.rawValue: // Resolved tab
            DataHandler.currentSegmentFilter = Filter.showResolved.rawValue
            DataHandler.refreshResolvedIncidents()
            tableView.reloadData()
        default:
            break
        }
}
  
    
    private func share() {
    DataHandler.saveToJSON()
    let activityController = UIActivityViewController(activityItems: [DataHandler.getJSON()!], applicationActivities: nil)
        
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
        self.present(activityController, animated: true, completion: nil)
    }
}

enum Filter: Int { // Remark: Need to match Segment in Story Board.
    case showAll = 0
    case showOpen
    case showInProgress
    case showResolved
}

// MARK: Extension - UITableViewDelegate
extension ListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: CustomCell = tableView.dequeueReusableCell(withIdentifier: "incidentCell", for: indexPath) as! CustomCell
        let incident: Incident
        switch filterSegmentedControl.selectedSegmentIndex {
        case Filter.showAll.rawValue: // Filter by All Incidents.
            incident = DataHandler.incidents[indexPath.row]
        case Filter.showOpen.rawValue: // Filter by Open Incidents
            incident = DataHandler.openIncidents[indexPath.row]
        case Filter.showInProgress.rawValue: // Filter by In Progress Incidents
            incident = DataHandler.inProgressIncidents[indexPath.row]
        case Filter.showResolved.rawValue: // Filter by Resolved Incidents
            incident = DataHandler.resolvedIncidents[indexPath.row]
        default: // Default by All Incidents.
            incident = DataHandler.incidents[indexPath.row]
        }
        cell.incidentTitleLabel?.text = "\(incident.type.rawValue) \(incident.identifier)"
        cell.incidentDescriptionLabel?.text = incident.description
        cell.incidentNumberOfPhotos?.text = "Photos:\(incident.countPictures())"
        cell.incidentNumberOfVideos?.text = "Videos:\(incident.countVideos())"
        cell.tag = incident.identifier
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
        case Filter.showResolved.rawValue: // Filter by Resolved Incidents
            return DataHandler.resolvedIncidents.count
        default: // Default by All Incidents.
            return DataHandler.incidents.count
        }
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let incident = DataHandler.incidents[indexPath.row]
            DataHandler.removeIncident(incidentToDelete: incident)
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
            return
        }
    }
    

}
