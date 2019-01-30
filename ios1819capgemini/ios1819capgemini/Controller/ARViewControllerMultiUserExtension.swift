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
        if !ARViewController.multiUserEnabled {
            return
        }
        do {
            let incidents = try JSONDecoder().decode([Incident].self, from: data)
            DataHandler.incidents = incidents
            for incident in incidents {
                for attachment in incident.attachments {
                    attachment.attachment.reevaluatePath()
                }
            }
        } catch {
    
        }
        do {
            let incident = try JSONDecoder().decode(Incident.self, from: data)
            if DataHandler.containsIncidentIdentifier(incident: incident) {
                DataHandler.replaceIncident(incident: incident)
                for attachment in incident.attachments {
                    attachment.attachment.reevaluatePath()
                }
                return
            }
            for attachment in incident.attachments {
                attachment.attachment.reevaluatePath()
            }
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
            guard let incident = ARViewController.editedIncident else {
                print("Edited Incident is nil")
                return
            }
            let data = try JSONEncoder().encode(incident)
            multipeerSession.sendToAllPeers(data)
            ARViewController.incidentEdited = false
            ARViewController.editedIncident = nil
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
        if !ARViewController.multiUserEnabled {
            return
        }
        do {
            let data = try JSONEncoder().encode(incident)
            self.multipeerSession.sendToAllPeers(data)
        } catch {
            
        }
    }
    
    func sendIncidents() {
        if !ARViewController.multiUserEnabled {
            return
        }
        sendIncidents(incidents: DataHandler.incidents)
    }

    func sendIncidents(incidents: [Incident]) {
        if !ARViewController.multiUserEnabled {
            return
        }
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
    

}
