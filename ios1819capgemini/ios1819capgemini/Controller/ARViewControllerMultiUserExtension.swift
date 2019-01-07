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
//swiftlint:disable all
extension ARViewController {
    
    func receivedData(_ data: Data, from peer: MCPeerID) {
        do {
            if let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
                print("world map decoded")
                let configuration = ARWorldTrackingConfiguration()
                configuration.planeDetection = .horizontal
                configuration.initialWorldMap = worldMap
                sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                mapProvider = peer
                print("world map: \(worldMap)")
                self.objectAnchor = worldMap.anchors.first as? ARObjectAnchor
//                self.detectedObjectNode = SCNNode()
//                detectedObjectNode?.position = SCNVector3(x: (worldMap.anchors.first?.transform.columns.3.x)!,
//                                                          y: (worldMap.anchors.first?.transform.columns.3.y)!,
//                                                          z: (worldMap.anchors.first?.transform.columns.3.z)!)
                addInfoPlane(carPart: objectAnchor?.referenceObject.name ?? "Unknown Car Part")
            }
        } catch {
            
        }
        do {
            let incidents = try JSONDecoder().decode([Incident].self, from: data)
            print("incident array decoded")
            if incidents.isEmpty {
                nodes = []
                automaticallyDetectedIncidents = []
            }
            DataHandler.incidents = incidents
        } catch {

        }
        do {
            let incident = try JSONDecoder().decode(Incident.self, from: data)
            DataHandler.incidents.append(incident)
//            print("incident : \(incident.identifier) = \(incident.getCoordinateToVector())")
        } catch {

        }
    }
    func updateNodes() {
        if detectedObjectNode == nil {
            return
        }
        for incident in DataHandler.incidents {
            if !existingIncidentNode(incident: incident) {
                add3DPin(vectorCoordinate: incident.getCoordinateToVector(), identifier: String(incident.identifier))
            }
        }
    }
    
    //called after incident is editted by a peer
    func updateIncidents() {
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
            print("sending editted incidents failed")
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
    
    private func updatePinColour(incidents: [Incident]) {
        for incident in incidents {
            for node in nodes {
                if node.name! == String(incident.identifier) {
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
