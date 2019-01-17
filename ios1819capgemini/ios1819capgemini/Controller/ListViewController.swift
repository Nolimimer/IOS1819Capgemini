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
    @IBOutlet weak var incidentStatus: UILabel!
    @IBOutlet weak var incidentNumberOfAttachments: UILabel!
}


// MARK: LastViewController
class ListViewController: UIViewController, UITableViewDelegate {
    
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
        self.navigationController?.navigationBar.setValue(true, forKey: "hidesShadow")
        tableView.delegate = self
        
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
        case Filter.showAll.rawValue:
            DataHandler.currentSegmentFilter = Filter.showAll.rawValue
            tableView.reloadData()
        case Filter.showOpen.rawValue:
            DataHandler.currentSegmentFilter = Filter.showOpen.rawValue
            DataHandler.refreshOpenIncidents()
            tableView.reloadData()
        case Filter.showInProgress.rawValue:
            DataHandler.currentSegmentFilter = Filter.showInProgress.rawValue
            DataHandler.refreshInProgressIncidents()
            tableView.reloadData()
        case Filter.showResolved.rawValue:
            DataHandler.currentSegmentFilter = Filter.showResolved.rawValue
            DataHandler.refreshResolvedIncidents()
            tableView.reloadData()
        default:
            break
        }
}
  
    
    private func share() {
        DataHandler.saveToJSON()
        guard let dataHandlerGetJason = DataHandler.getJSON() else {
            print("Error")
            return
        }
        let activityController = UIActivityViewController(activityItems: [dataHandlerGetJason], applicationActivities: nil)
        
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
        case Filter.showAll.rawValue:
            incident = DataHandler.incidents[indexPath.row]
        case Filter.showOpen.rawValue:
            incident = DataHandler.openIncidents[indexPath.row]
        case Filter.showInProgress.rawValue:
            incident = DataHandler.inProgressIncidents[indexPath.row]
        case Filter.showResolved.rawValue:
            incident = DataHandler.resolvedIncidents[indexPath.row]
        default:
            incident = DataHandler.incidents[indexPath.row]
        }

        cell.incidentTitleLabel?.text = "\(incident.type.rawValue)"
        cell.incidentDescriptionLabel?.text = incident.description
        cell.incidentStatus?.text = "\(incident.status.rawValue)"
        cell.incidentNumberOfAttachments?.text = "Attachments: \(incident.attachments.count)"
        //cell.textLabel?.text = "\(incident.type.rawValue)"
        cell.tag = incident.identifier
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch filterSegmentedControl.selectedSegmentIndex {
        case Filter.showAll.rawValue:
            ARViewController.filterAllIncidents()
            return DataHandler.incidents.count
        case Filter.showOpen.rawValue:
            ARViewController.filterOpenIncidents()
            return DataHandler.openIncidents.count
        case Filter.showInProgress.rawValue:
            ARViewController.filterInProgressIncidents()
            return DataHandler.inProgressIncidents.count
        case Filter.showResolved.rawValue:
            ARViewController.filterResolvedIncidents()
            return DataHandler.resolvedIncidents.count
        default:
            ARViewController.filterAllIncidents()
            return DataHandler.incidents.count
        }
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if ARViewController.connectedToPeer {
                let alert = UIAlertController(title: "Error",
                                              message: "Incident can't be deleted if Peer is connected",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK",
                                              style: .default,
                                              handler: nil))
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            } else {
                creatingNodePossible = false
                let incident = DataHandler.incidents[indexPath.row]
                DataHandler.removeIncident(incidentToDelete: incident)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                return
            }
        }
    }
    
//    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
//
//    }
    private func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        var title = "Stop"
        var incident: Incident?
        if ARViewController.navigatingIncident == incident {
            title = "Navigate"
        }
        let navigate = UITableViewRowAction(style: .normal, title: title) { _, _ in
            self.dismiss(animated: true, completion: {

                switch self.filterSegmentedControl.selectedSegmentIndex {
                case 0:
                    incident = DataHandler.incidents[indexPath.row]
                case 1:
                    incident = DataHandler.openIncidents[indexPath.row]
                case 2:
                    incident = DataHandler.inProgressIncidents[indexPath.row]
                case 3:
                    incident = DataHandler.resolvedIncidents[indexPath.row]
                default:
                    incident = DataHandler.incidents[indexPath.row]
                }

                creatingNodePossible = true
                if ARViewController.navigatingIncident == incident {
                    ARViewController.navigatingIncident = nil
                } else {
                    ARViewController.navigatingIncident = incident
                }
            })
        }
        if title == "Stop" {
            navigate.backgroundColor = UIColor.orange
        } else {
            navigate.backgroundColor = UIColor.appGreen
        }
        
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { _, _ in
            if ARViewController.connectedToPeer {
                let alert = UIAlertController(title: "Error",
                                              message: "Incident can't be deleted if Peer is connected",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK",
                                              style: .default,
                                              handler: nil))
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            } else {
                creatingNodePossible = true
                let incident = DataHandler.incidents[indexPath.row]
                DataHandler.removeIncident(incidentToDelete: incident)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                return
            }
        }
        delete.backgroundColor = UIColor.red
        
        return [delete, navigate]
    }
}
