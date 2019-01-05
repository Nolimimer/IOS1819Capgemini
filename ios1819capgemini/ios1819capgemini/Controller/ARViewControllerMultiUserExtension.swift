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
            //received world map
            if let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
                let configuration = ARWorldTrackingConfiguration()
                configuration.planeDetection = .horizontal
                configuration.initialWorldMap = worldMap
                statusViewController.showMessage("world map received", autoHide: true)
                sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
                mapProvider = peer
                }
            //anchor of detected object has been set and sent
            else if let anchor = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARObjectAnchor.self, from: data) {
                // Add anchor to the session, ARSCNView delegate adds visible content.
                statusViewController.showMessage("anchor received", autoHide: true)
                self.objectAnchor = anchor
                addInfoPlane(carPart: objectAnchor?.referenceObject.name ?? "Unknown Car Part")
                }
            //node of detected object has been sent (we only save and send 1 node)
            else if let node = try NSKeyedUnarchiver.unarchivedObject(ofClass: SCNNode.self, from: data) {
                statusViewController.showMessage("detected object node received", autoHide: true)
                self.detectedObjectNode = node
            } else {
            //check if incident has been sent by peer (either as array or class) and react accordingly
                do {
                    let incidents = try JSONDecoder().decode([Incident].self, from: data)
                    statusViewController.showMessage("incidents array received", autoHide: true)
                    DataHandler.incidents = incidents
                    for incident in DataHandler.incidents {
                        add3DPin(vectorCoordinate: incident.getCoordinateToVector(),
                                 identifier: String(incident.identifier))
                    }
                } catch _ {
                    print("Decoding incident array failed")
                }
                do {
                    let incident = try JSONDecoder().decode(Incident.self, from: data)
                    statusViewController.showMessage("single incident received", autoHide: true)
                    DataHandler.incidents.append(incident)
                    add3DPin(vectorCoordinate: incident.getCoordinateToVector(),
                             identifier: String(incident.identifier))
                } catch _ {
                    print("Decoding single incident failed")
                }
            }
        } catch _ {
            print("can't decode data received from \(peer)")
        }
    }
}
