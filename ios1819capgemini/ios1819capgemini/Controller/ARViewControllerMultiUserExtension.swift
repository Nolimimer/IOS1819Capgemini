//
//  ARViewControllerMultiUserExtension.swift
//  ios1819capgemini
//
//  Created by Minh Tran on 05.01.19.
//  Copyright © 2019 TUM LS1. All rights reserved.
//

import Foundation
import ARKit
import MultipeerConnectivity

extension ARViewController {
    
    func receivedData(_ data: Data, from peer: MCPeerID) {
        do {
            let incidents = try JSONDecoder().decode([Incident].self, from: data)
            DataHandler.incidents = incidents
            
        } catch {
            
        }
        do {
            let incident = try JSONDecoder().decode(Incident.self, from: data)
            DataHandler.incidents.append(incident)
        } catch {
            
        }
    }
    //called after incident is editted by a peer
    func incidentEditted() {
        if !ARViewController.incidentEdited {
            return
        }
        do {
            let data = try JSONEncoder().encode(DataHandler.incidents)
            multipeerSession.sendToAllPeers(data)
            ARViewController.incidentEdited = false
        } catch _ {
            let notification = UINotificationFeedbackGenerator()
            
            DispatchQueue.main.async {
                notification.notificationOccurred(.error)
            }
        }
    }
    
    private func existingIncidentNode(incident: Incident) -> Bool {
        
        for node in nodes {
            if node.name == String(incident.identifier) {
                return true
            }
        }
        return false
    }
    
    func sendIncident(incident: Incident) {
        do {
            let data = try JSONEncoder().encode(incident)
            self.multipeerSession.sendToAllPeers(data)
        } catch {
            
        }
    }
    
    func sendIncidents() {
        sendIncidents(incidents: DataHandler.incidents)
    }

    func sendIncidents(incidents: [Incident]) {
        do {
            let data = try JSONEncoder().encode(incidents)
            self.multipeerSession.sendToAllPeers(data)
        } catch {
            
        }
    }
    
    func getIncident(identifier: String) -> Incident? {
        return DataHandler.incidents.first(where: { String($0.identifier) == identifier })
    }
    
    func checkIncidentDeleted(identifier: String) -> Bool {
        for incident in DataHandler.incidents where "\(incident.identifier)" == identifier {
            return false
        }
        return true
    }
    
    func updatePinColour() {
        for incident in DataHandler.incidents {
            if incident.automaticallyDetected {
                nodes.first(where: { $0.name == "\(incident.identifier)" })?.geometry?.materials.first?.diffuse.contents = UIColor.blue
            } else {
                for node in nodes {
                    guard let nodeName = node.name else {
                        print("Error")
                        return
                    }
                    if nodeName == String(incident.identifier) {
                        switch incident.status {
                        case .open: node.geometry?.materials.first?.diffuse.contents = UIColor.red
                        case .progress: node.geometry?.materials.first?.diffuse.contents = UIColor.yellow
                        case .resolved: node.geometry?.materials.first?.diffuse.contents = UIColor.green
                        }
                    }
                }
            }
        }
    }
}
