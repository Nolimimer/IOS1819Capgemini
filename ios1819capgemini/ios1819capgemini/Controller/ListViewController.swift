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
    @IBOutlet weak var statusImage: UIImageView!
}


// MARK: LastViewController
class ListViewController: UIViewController, UITableViewDelegate {
    
    var currentSegmentFilter = 0
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
        filterSegmentedControl.selectedSegmentIndex = currentSegmentFilter
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
        ARViewController.selectedCarPart?.incidents = DataHandler.incidents
        share()
    }
    
    
    @IBAction private func selectedFilterSegment(_ sender: UISegmentedControl) {
        tableView.reloadData()
    }
  
    
    private func share() {
        var data: Data?
//        guard let carPart = ARViewController.selectedCarPart else {
//            print("selected car part is empty")
//            return
//        }
        if let carPart = ARViewController.selectedCarPart {
            DataHandler.saveToJSON(carPart: carPart)
            data = DataHandler.getJSONCurrentCarPart()
        } else {
            data = DataHandler.getJSON()
        }
//        DataHandler.saveToJSON(carPart: carPart)
//        guard let dataHandlerGetJason = DataHandler.getJSON() else {
//            print("share error")
//            return
//        }
        
//        guard let dataHandlerGetCarPart = DataHandler.getJSONCurrentCarPart() else {
//            print("json file current car part does not have any data")
//            return
//        }
        if data == nil {
            print("I fucked up")
            return
        }
        let activityController = UIActivityViewController(activityItems: [data!], applicationActivities: nil)
        
            let excludedActivities =
                [UIActivity.ActivityType.mail,
                 UIActivity.ActivityType.addToReadingList,
                 UIActivity.ActivityType.assignToContact,
                 UIActivity.ActivityType.copyToPasteboard,
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

// MARK: Extension - UITableViewDelegate
extension ListViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: CustomCell = tableView.dequeueReusableCell(withIdentifier: "incidentCell", for: indexPath) as! CustomCell
        let incident: Incident
        let incidents: [Incident]
        switch filterSegmentedControl.selectedSegmentIndex {
        case 1:
            incidents = DataHandler.incidents.filter { $0.status == .open }
            incident = incidents[indexPath.row]
        case 2:
            incidents = DataHandler.incidents.filter { $0.status == .progress }
            incident = incidents[indexPath.row]
        case 3:
            incidents = DataHandler.incidents.filter { $0.status == .resolved }
            incident = incidents[indexPath.row]
        default:
            incident = DataHandler.incidents[indexPath.row]
        }

        cell.incidentTitleLabel?.text = "\(incident.type.rawValue)"
        cell.incidentDescriptionLabel?.text = incident.description

        switch incident.status {
            case .open:
                cell.statusImage.image = #imageLiteral(resourceName: "red")
            case .progress:
                cell.statusImage.image = #imageLiteral(resourceName: "orange")
            case .resolved:
                cell.statusImage.image = #imageLiteral(resourceName: "green")
        }

        cell.tag = incident.identifier
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !ARViewController.objectDetected {
            return 0
        }
        switch filterSegmentedControl.selectedSegmentIndex {
        case 1:
            ARViewController.filterOpenIncidents()
            return (DataHandler.incidents.filter { $0.status == .open }).count
        case 2:
            ARViewController.filterInProgressIncidents()
            return (DataHandler.incidents.filter { $0.status == .progress }).count
        case 3:
            ARViewController.filterResolvedIncidents()
            return (DataHandler.incidents.filter { $0.status == .resolved }).count
        default:
            ARViewController.filterAllIncidents()
            return DataHandler.incidents.count
        }
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            var incidents: [Incident]
            switch self.filterSegmentedControl.selectedSegmentIndex {
            case 1:
                incidents = DataHandler.incidents.filter { $0.status == .open }
            case 2:
                incidents = DataHandler.incidents.filter { $0.status == .progress }
            case 3:
                incidents = DataHandler.incidents.filter { $0.status == .resolved }
            default:
                incidents = DataHandler.incidents
            }
            let incident = incidents[indexPath.row]
            
            if ARViewController.connectedToPeer && ARViewController.multiUserEnabled {
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
            }
            if ARViewController.navigatingIncident != nil {
                let alert = UIAlertController(title: "Error",
                                              message: "Incident can't be deleted if navigation is enabled ",
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
        
        var incidents: [Incident]
        var currentIncident: Incident?
        switch self.filterSegmentedControl.selectedSegmentIndex {
        case 1:
            incidents = DataHandler.incidents.filter { $0.status == .open }
        case 2:
            incidents = DataHandler.incidents.filter { $0.status == .progress }
        case 3:
            incidents = DataHandler.incidents.filter { $0.status == .resolved }
        default:
            incidents = DataHandler.incidents
        }
        currentIncident = incidents[indexPath.row]
        if currentIncident == ARViewController.navigatingIncident {
            title = "Stop"
        } else {
            title = "Navigate"
        }
        let navigate = UITableViewRowAction(style: .normal, title: title) { _, _ in
            self.dismiss(animated: true, completion: {
                creatingNodePossible = true
                if ARViewController.navigatingIncident == currentIncident {
                    ARViewController.navigatingIncident = nil
                } else {
                    ARViewController.navigatingIncident = currentIncident
                }
            })
        }
        if title == "Stop" {
            navigate.backgroundColor = UIColor.orange
        } else {
            navigate.backgroundColor = UIColor.appGreen
        }
        
        
        let delete = UITableViewRowAction(style: .destructive, title: "Delete") { _, _ in
            if ARViewController.connectedToPeer && ARViewController.multiUserEnabled {
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
            }
            if ARViewController.navigatingIncident != nil {
                let alert = UIAlertController(title: "Error",
                                              message: "Incident can't be deleted if it is navigated to ",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK",
                                              style: .default,
                                              handler: nil))
                DispatchQueue.main.async {
                    self.present(alert, animated: true, completion: nil)
                }
                return
            }
            else {
                creatingNodePossible = true
                guard let currentIncident = currentIncident else { return }
                DataHandler.removeIncident(incidentToDelete: currentIncident)
                self.tableView.deleteRows(at: [indexPath], with: .automatic)
                return
            }
        }
        delete.backgroundColor = UIColor.red
        
        return [delete, navigate]
    }
}
