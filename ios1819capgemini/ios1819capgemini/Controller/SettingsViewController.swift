//
//  SettingsViewController.swift
//  ios1819capgemini
//
//  Created by Minh Tran on 27.12.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//
import UIKit
import Foundation

//swiftlint:disable all
class SettingsViewController: UIViewController {
    
    @IBOutlet private weak var tableView: UITableView!
    @IBAction func saveSettingsButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    var data = [Setting]()
    override func viewDidLoad() {
        super.viewDidLoad()
        data = UserDefaults.getCurrentSettingsFormalized()

        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = UIScreen.main.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.navigationController?.view.addSubview(blurView)
        self.navigationController?.view.sendSubviewToBack(blurView)
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        self.modalPresentationStyle = .overCurrentContext
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.view.bringSubviewToFront(tableView)
    }
}
extension SettingsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "settingsCell", for: indexPath)
        let setting = Array(data)[indexPath.row]
        cell.textLabel?.text = setting.key
        cell.tag = indexPath.section
        let switchView = UISwitch(frame: .zero)
        if setting.value {
            switchView.setOn(true, animated: true)
            switchView.tag = indexPath.row
            switchView.addTarget(self, action: #selector(self.switchChanged(_:)), for: .valueChanged)
            cell.accessoryView = switchView
        }
        else {
            switchView.setOn(false, animated: true)
            switchView.tag = indexPath.row
            switchView.addTarget(self, action: #selector(self.switchChanged(_:)), for: .valueChanged)
            cell.accessoryView = switchView
        }
        return cell
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    @objc func switchChanged(_ sender : UISwitch!){
        switch sender.tag {
        case 0:
            UserDefaults.standard.setNavigationArrows(value: sender.isOn)
        case 1:
            UserDefaults.standard.setFeaturePoints(value: sender.isOn)
        case 2:
            UserDefaults.standard.setBoundingBoxes(value: sender.isOn)
        case 3:
            UserDefaults.standard.setIncidentDistance(value: sender.isOn)
        case 4:
            UserDefaults.standard.setPlacePinsBeforeDetection(value: sender.isOn)
        case 5:
            UserDefaults.standard.setInfoPlane(value: sender.isOn)
        case 6:
            UserDefaults.standard.setAutomaticDetection(value: sender.isOn)
        case 7:
            UserDefaults.standard.setHapticFeedback(value: sender.isOn)
        default:
            return
        }
    }
}
