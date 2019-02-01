//
//  ARViewControllerSessionExtension.swift
//  ios1819capgemini
//
//  Created by Minh Tran on 14.01.19.
//  Copyright © 2019 TUM LS1. All rights reserved.
//

import Foundation
import ARKit

extension ARViewController {
    
    func updateIncidents() {
        
        if !ARViewController.objectDetected {
            return
        }
        incidentEditted()
        for incident in DataHandler.incidents {
            if incidentHasNotBeenPlaced(incident: incident) {
                guard let detectedObjectNode = detectedObjectNode else {
                    print("detected object node not initialized in updateIncidents() ")
                    ARViewController.objectDetected = false
                    return
                }
                let coordinateRelativeObject = detectedObjectNode.convertPosition(incident.getCoordinateToVector(), to: nil)
                add3DPin(vectorCoordinate: coordinateRelativeObject, identifier: "\(incident.identifier)")
            }
        }
    }
    
    func checkConnection () {
        if !multipeerSession.connectedPeers.isEmpty && ARViewController.multiUserEnabled {
            ARViewController.connectedToPeer = true
//            let peerNames = multipeerSession.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
            connectionLabel.text = "Connected"
            connectionLabel.textColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        } else {
            connectionLabel.text = ""
        }
    }
    
    func checkReset() {
        if !ARViewController.resetButtonPressed {
            return
        } else {
            reset()
            ARViewController.resetButtonPressed = false
        }
    }
    
    func checkSendIncidents() {
        if !ARViewController.sendIncidentButtonPressed {
            return
        } else {
            sendIncidents()
            ARViewController.sendIncidentButtonPressed = false
        }
    }
    func refreshNodes() {
        
        for node in nodes {
            guard let name = node.name else {
                return
            }
            if DataHandler.incidents.isEmpty {
                do {
                    let data = try JSONEncoder().encode(DataHandler.incidents)
                    self.multipeerSession.sendToAllPeers(data)
                } catch {
                    print("sending incidents array failed (refreshNodes DataHandler.incidents.isEmpty)")
                }
            }
            if DataHandler.incident(withId: name) == nil {
                self.scene.rootNode.childNode(withName: name, recursively: false)?.removeFromParentNode()
                deleteNode(identifier: name)
                do {
                    let data = try JSONEncoder().encode(DataHandler.incidents)
                    self.multipeerSession.sendToAllPeers(data)
                } catch {
                    print("sending incidents array failed (refreshNodes DataHandler.incident(withId: name) == nil")
                }
            }
        }
    }
    
    func updatePinColour() {
        for incident in DataHandler.incidents {
            for node in nodes {
                guard let nodeName = node.name else {
                    print("node.name == nil in updatePinColour()")
                    return
                }
                if nodeName == String(incident.identifier) {
                    switch incident.status {
                    case .open:
                        if incident.automaticallyDetected {
                            node.geometry?.materials.first?.diffuse.contents = UIColor.blue
                        } else {
                            node.geometry?.materials.first?.diffuse.contents = UIColor.red
                        }
                    case .progress: node.geometry?.materials.first?.diffuse.contents = UIColor.yellow
                    case .resolved: node.geometry?.materials.first?.diffuse.contents = UIColor.green
                    }
                }
            }
        }
    }
    
    func sessionShouldAttemptRelocalization(_ session: ARSession) -> Bool {
        return true
    }
    
    func checkVisibleNodes() {
        var tmp: [SCNNode] = []
        for node in nodes {
            if nodeVisibleToUser(node: node) {
                tmp.append(node)
            }
        }
        visibleNodes = tmp
    }
    
    func mapVisibleNodesToPosition() {
        var tmp: [SCNNode: CGPoint] = [:]
        for node in visibleNodes {
            let vector = node.presentation.worldPosition
            let projectedNode = self.sceneView.projectPoint(vector)
            let point = CGPoint(x: CGFloat(projectedNode.x), y: CGFloat(projectedNode.y))
            tmp[node] = point
        }
        visibleNodesPosition = tmp
    }
    
    func loadCustomScans() {
        
        let fileManager = FileManager.default
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            for file in fileURLs {
                if file.lastPathComponent.hasSuffix(".arobject") {
                    let arRefereceObject = try ARReferenceObject(archiveURL: file)
                    detectionObjects.insert(arRefereceObject)
                }
            }
        } catch {
            print("Error loading custom scans")
        }
        DataHandler.setCarParts()
    }
    
    func checkSettings() {
        
        if UserDefaults.standard.bool(forKey: "enable_boundingboxes") {
            sceneView.debugOptions = [.showFeaturePoints, .showBoundingBoxes]
        } else if UserDefaults.standard.bool(forKey: "enable_featurepoints") {
            sceneView.debugOptions = [.showFeaturePoints]
        } else {
            sceneView.debugOptions = []
        }
        ARViewController.multiUserEnabled = UserDefaults.standard.bool(forKey: "multi_user")
        
        if !ARViewController.multiUserEnabled {
            multipeerSession.disconnectSession()
        }
        
        if UserDefaults.standard.bool(forKey: "enable_detection") && detectedObjectNode != nil {
            isDetecting = true
            setupBoxes()
        } else {
            hideBoxes()
            isDetecting = false
        }
    }
    
    func checkTappingCreateButtonPossible() {
        if !ARViewController.tappingCreateIncidentButtonPossible {
            createIncidentButton.isHidden = true
            createIncidentButton.isEnabled = false
        } else {
            createIncidentButton.isHidden = false
            createIncidentButton.alpha = 1.0
            createIncidentButton.backgroundColor = #colorLiteral(red: 0, green: 0.5762649179, blue: 1, alpha: 1)
            createIncidentButton.isEnabled = true
        }
    }
    
    func updateSession(for trackingState: ARCamera.TrackingState, incident: Incident?) {
        
        checkTappingCreateButtonPossible()
        checkSettings()
        checkConnection()
        checkReset()
        checkSendIncidents()
        updateIncidents()
        if !ARViewController.multiUserEnabled && !ARViewController.connectedToPeer {
            refreshNodes()
        }
        checkVisibleNodes()
        mapVisibleNodesToPosition()
        updatePinColour()
        setDescriptionLabel()
        setNavigationArrows(for: trackingState, incident: incident)
        ARViewController.tappingCreateIncidentButtonPossible = false
    }
    
}
