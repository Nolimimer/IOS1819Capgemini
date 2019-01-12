//
//  ARViewControllerNavigation.swift
//  ios1819capgemini
//
//  Created by Minh Tran on 29.12.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

import Foundation
import ARKit

//swiftlint:disable all
extension ARViewController {
    
    // MARK: Navigation methods
    /*
     Helper methods to calculate distances between incident and camera
     */
    func distanceTravelled(xDist: Float, yDist: Float, zDist: Float) -> Float {
        return sqrt((xDist * xDist) + (yDist * yDist) + (zDist * zDist))
    }
    
    func distanceTravelled(between v1: SCNVector3, and v2: SCNVector3) -> Float {
        
        let xDist = v1.x - v2.x
        let yDist = v1.y - v2.y
        let zDist = v1.z - v2.z
        
        return distanceTravelled(xDist: xDist, yDist: yDist, zDist: zDist)
    }
    
    static func getNodeOfIncident(incident: Incident) -> SCNNode? {
        return nodes.first(where: { String(incident.identifier) == $0.name })
    }
    
    static func getIncidentOfNode(node: SCNNode) -> Incident? {
        return DataHandler.incidents.first(where: { node.name == String($0.identifier) })
    }
    
    func distanceIncidentNodeCamera(incident: Incident) -> Float? {
        
        guard let node = ARViewController.getNodeOfIncident(incident: incident) else {
            return nil
        }
        guard let currentFrame = self.sceneView.session.currentFrame else {
            return nil
        }
        return distanceTravelled(between: SCNVector3(x: currentFrame.camera.transform.columns.3.x,
                                                     y: currentFrame.camera.transform.columns.3.y,
                                                     z: currentFrame.camera.transform.columns.3.z),
                                 and: node.position)
    }
    
    func navigationToIncident (incident: Incident?) -> String? {
        
        guard let incident = incident else {
            return "error"
        }
        guard let node = ARViewController.getNodeOfIncident(incident: incident) else {
            return "error"
        }
        guard let distanceNode = incidentNodePosToPOV(node: node) else {
            return "error"
        }
        guard var distanceCamera = distanceCameraNode(incident: incident) else {
            return "error"
        }
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        distanceCamera *= 100
        guard let distance = formatter.string(from: NSNumber(value: distanceCamera)) else {
            return "Error"
        }
        if nodeVisibleToUser(node: node) {
            return "Distance: \(distance)cm "
        }
        if abs(distanceNode.x) > abs(distanceNode.y) {
            if distanceNode.x.isLess(than: 0.0) {
                return "left"
            } else {
                return "right"
            }
        } else {
            if distanceNode.y.isLess(than: 0.0) {
                return "down"
            } else {
                return "up"
            }
        }
    }
    
    func distanceCameraNode (incident: Incident?) -> Float? {
        
        guard let currentFrame = self.sceneView.session.currentFrame, let incident = incident else {
            return nil
        }
        let node = ARViewController.getNodeOfIncident(incident: incident)
        
        return distanceTravelled(between: SCNVector3 (x: currentFrame.camera.transform.columns.3.x,
                                                     y: currentFrame.camera.transform.columns.3.y,
                                                     z: currentFrame.camera.transform.columns.3.z),
                                 and: self.sceneView.scene.rootNode.convertPosition(node!.position, to: nil))
    }
    
//    func distanceCameraNode (incident: Incident?) -> Float? {
//
//        guard let currentFrame = self.sceneView.session.currentFrame, let incident = incident else {
//            return nil
//        }
//        return distanceTravelled(between: SCNVector3(x: currentFrame.camera.transform.columns.3.x,
//                                                     y: currentFrame.camera.transform.columns.3.y,
//                                                     z: currentFrame.camera.transform.columns.3.z),
//                                 and: self.sceneView.scene.rootNode.convertPosition(SCNVector3(incident.coordinate.pointX,
//                                                                                               incident.coordinate.pointY,
//                                                                                               incident.coordinate.pointZ),
//                                                                                    to: nil))
//    }
    /*
     return the closest incident with status open
     */
    func closestOpenIncident () -> Incident? {

        let openIncidents = DataHandler.incidents.filter({ $0.status == .open })
        var openIncidentsDistances = [Float: Incident]()
        for incident in openIncidents {
            guard let distance = distanceCameraNode(incident: incident) else {
                return nil
            }
            openIncidentsDistances[distance] = incident
        }
        let closestIncident = openIncidentsDistances.min { a, b in a.key < b.key }
        guard let incident = closestIncident else {
            return nil
        }
        return incident.value
    }
    
    /*
     calculates the distance of an input node to the camera on each of the 3 axis,
     */
//    func incidentPosToCamera (incident: Incident?) -> SCNVector3? {
//        guard let currentFrame = self.sceneView.session.currentFrame, let incident = incident else {
//            return nil
//        }
//        let worldCoordinate = sceneView.scene.rootNode.convertPosition(SCNVector3(incident.coordinate.pointX,
//                                                                                  incident.coordinate.pointY,
//                                                                                  incident.coordinate.pointZ),
//                                                                       to: nil)
//        return SCNVector3(x: ((worldCoordinate.x - currentFrame.camera.transform.columns.3.x) * 100 ),
//                          y: ((worldCoordinate.y - currentFrame.camera.transform.columns.3.y) * 100 ),
//                          z: ((worldCoordinate.z - currentFrame.camera.transform.columns.3.z) * 100))
//    }

    /*
     returns the position of the input incident to the point of view, useful for rotational purposes
     */
//    func incidentPosToPOV(incident : Incident?) -> SCNVector3? {
//        guard let incident = incident else {
//            return nil
//        }
//        let position = SCNVector3(x: incident.coordinate.pointX,
//                                  y: incident.coordinate.pointY,
//                                  z: incident.coordinate.pointZ)
//        var incidentPositionToPOV = scene.rootNode.convertPosition(position, to: sceneView.pointOfView)
//        incidentPositionToPOV.x *= 100
//        incidentPositionToPOV.y *= 100
//        incidentPositionToPOV.z *= 100
//        return incidentPositionToPOV
//    }
    
    
    /*
     returns the position of the node relative to the point of view
     */
    func incidentNodePosToPOV(node: SCNNode?) -> SCNVector3? {
        
        guard let node = node else {
            return nil
        }
        let position = node.position
        var incidentNodePositionToPOV = scene.rootNode.convertPosition(position, to: sceneView.pointOfView)
        incidentNodePositionToPOV.x *= 100
        incidentNodePositionToPOV.y *= 100
        incidentNodePositionToPOV.z *= 100
        return incidentNodePositionToPOV
    }
    
    
    /*
     returns true if the input node can be seen through the camera, otherwise false
     */
    func nodeVisibleToUser(node: SCNNode) -> Bool {
        
        if let pov  = sceneView.pointOfView {
            let isVisible = sceneView.isNode(node, insideFrustumOf: pov)
            let notification = UINotificationFeedbackGenerator()
            if isVisible {
                DispatchQueue.main.async {
                    notification.notificationOccurred(.success)
                }
                return isVisible
            } else {
                return isVisible
            }
        }
        return false
    }
    
    func toggleIncidentsOpacityExceptNavigating() {
        guard let incident = ARViewController.navigatingIncident else {
            return
        }
        for node in nodes where node.name != String(incident.identifier) && node.name != "info-plane"{
            node.opacity = 0.45
            
        }
    }
    
    func restoreIncidentOpacity() {
        for node in nodes where node.name != "info-plane" {
            node.opacity = 1
        }
    }
    
    func animateNavigatingIncident(incident: Incident?) {
        guard let incident = incident, let node = ARViewController.getNodeOfIncident(incident: incident) else {
            return
        }
        node.runAction(nodeBlinking)
    }
    /*
     sets navigation buttons based on the navigation which is given
     */
    func setNavigationArrows(for trackingState: ARCamera.TrackingState, incident: Incident?) {
        
        if !ARViewController.objectDetected {
            return 
        }
        guard let incident = incident else {
            return
        }
        animateNavigatingIncident(incident: incident)
        arrowUp.isHidden = true
        arrowDown.isHidden = true
        arrowRight.isHidden = true
        arrowLeft.isHidden = true
        
        let navigationSuggestion = navigationToIncident(incident: incident)
        guard let suggestion = navigationSuggestion else {
            statusViewController.showMessage("Error", autoHide: true)
            return
        }
        switch suggestion {
        case "up":
            statusViewController.showTrackingQualityInfo(for: trackingState, autoHide: true)
            arrowUp.isHidden = false
        case "down":
            statusViewController.showTrackingQualityInfo(for: trackingState, autoHide: true)
            arrowDown.isHidden = false
        case "right":
            statusViewController.showTrackingQualityInfo(for: trackingState, autoHide: true)
            arrowRight.isHidden = false
        case "left":
            statusViewController.showTrackingQualityInfo(for: trackingState, autoHide: true)
            arrowLeft.isHidden = false
        default:
            statusViewController.showMessage(suggestion, autoHide: true)
        }
    }

    static func filterOpenIncidents() {
        for node in nodes {
            guard let incident = ARViewController.getIncidentOfNode(node: node) else { return }
            if incident.status != .open {
                node.opacity = 0.1
            } else {
                node.opacity = 1.0
            }
        }
    }
    static func filterInProgressIncidents() {
        for node in nodes {
            guard let incident = ARViewController.getIncidentOfNode(node: node) else { return }
            if incident.status != .progress {
                node.opacity = 0.1
            } else {
                node.opacity = 1.0
            }
        }
    }
    static func filterResolvedIncidents() {
        for node in nodes {
            guard let incident = ARViewController.getIncidentOfNode(node: node) else { return }
            if incident.status != .resolved {
                node.opacity = 0.1
            } else {
                node.opacity = 1.0
            }
        }
    }
    static func filterAllIncidents() {
        nodes.forEach({ $0.opacity = 1 })
    }
}
