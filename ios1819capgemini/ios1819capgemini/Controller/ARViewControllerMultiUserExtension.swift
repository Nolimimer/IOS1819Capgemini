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
    
    //swiftlint:disable all
    func receivedData(_ data: Data, from peer: MCPeerID) {
//        print("received data executed")
        do {
//            received world map
            if let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
                print("world map decoded")
                let configuration = ARWorldTrackingConfiguration()
                configuration.planeDetection = .horizontal
                configuration.initialWorldMap = worldMap
                statusViewController.showMessage("world map received", autoHide: true)
                sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                mapProvider = peer
                print("world map: \(worldMap)")
            }
        } catch {
//            print("not world map")
        }
        do {
            if let anchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARObjectAnchor.self, from: data) {
                print("anchor decoded")
                // Add anchor to the session, ARSCNView delegate adds visible content.
                statusViewController.showMessage("anchor received", autoHide: true)
                self.objectAnchor = anchor
                self.sceneView.session.add(anchor: anchor)
                print("object anchor: \(objectAnchor)")
                addInfoPlane(carPart: objectAnchor?.referenceObject.name ?? "Unknown Car Part")
            }
        } catch {
//            print("not anchor")
        }
        do {
            if let node = try NSKeyedUnarchiver.unarchivedObject(ofClass: SCNNode.self, from: data) {
                print("node decoded")
                statusViewController.showMessage("detected object node received", autoHide: true)
                self.detectedObjectNode = node
                print("detected object node: \(detectedObjectNode)")
            }
        } catch {
//            print("not node")
        }
        do {
            let incidents = try JSONDecoder().decode([Incident].self, from: data)
            print("incident array decoded")
            statusViewController.showMessage("incidents array received", autoHide: true)
            if incidents.isEmpty {
                nodes = []
                automaticallyDetectedIncidents = []
            }
            DataHandler.incidents = incidents
            for incident in DataHandler.incidents {
                add3DPin(vectorCoordinate: incident.getCoordinateToVector(),
                         identifier: String(incident.identifier))
                print("incident : \(incident.identifier) = \(incident.getCoordinateToVector())")
            }
//            updatePinColour(incidents: DataHandler.incidents)
        } catch {
//            print("not incident array")
        }
        do {
            let incident = try JSONDecoder().decode(Incident.self, from: data)
            print("trying to decode incident")
            statusViewController.showMessage("single incident received", autoHide: true)
            DataHandler.incidents.append(incident)
            add3DPin(vectorCoordinate: incident.getCoordinateToVector(),
                     identifier: String(incident.identifier))
            print("incident : \(incident.identifier) = \(incident.getCoordinateToVector())")
        } catch {
//            print("not incident")
        }
    }
    func updateNodes() {
        for incident in DataHandler.incidents {
            let coordinateRelativeToWorld = sceneView.scene.rootNode.convertPosition(
                SCNVector3(incident.getCoordinateToVector().x,
                           incident.getCoordinateToVector().y,
                           incident.getCoordinateToVector().z),
                to: nil)
            add3DPin(vectorCoordinate: coordinateRelativeToWorld, identifier: String(incident.identifier))
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
