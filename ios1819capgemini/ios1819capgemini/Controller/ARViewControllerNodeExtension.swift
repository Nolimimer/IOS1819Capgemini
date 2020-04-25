//
//  ARViewControllerNodeExtension.swift
//  ios1819capgemini
//
//  Created by Minh Tran on 13.01.19.
//  Copyright © 2019 TUM LS1. All rights reserved.
//

import Foundation
import ARKit
import Vision

extension ARViewController {
    
    /*
     returns true if there is a node in a certain radius from the coordinate
     */
    func calculateNodesInRadius(coordinate: CGPoint, radius: CGFloat) -> Bool {
        
        for incident in automaticallyDetectedIncidents {
            if abs(incident.x.distance(to: coordinate.x)) < radius || abs(incident.y.distance(to: coordinate.y)) < radius {
                return false
            }
        }
        return true
    }
    
    func calculateNodesInRadius(coordinate: SCNVector3, radius: Float) -> Bool {
        
        for vector in automaticallyDetectedVectors {
            if checkRange(origin: vector, pos: coordinate, radius: radius) {
                return false
            }
        }
        return true
    }
    
    func incidentHasNotBeenPlaced (incident: Incident) -> Bool {
        
        for node in nodes {
            if String(incident.identifier) == node.name {
                return false
            }
        }
        return true
    }
    
    func deleteNode(identifier: String) {
        for (index, node) in nodes.enumerated() where node.name == identifier {
            nodes.remove(at: index)
            return
        }
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
    
    func getNodeInRadius(hitResult: ARHitTestResult, radius: Float) -> SCNNode? {
        let coordinateVector = SCNVector3(hitResult.worldTransform.columns.3.x,
                                          hitResult.worldTransform.columns.3.y,
                                          hitResult.worldTransform.columns.3.z)
        for node in nodes {
            if checkRange(origin: node.position, pos: coordinateVector, radius: radius) {
                return node
            }
        }
        return nil
    }
    
    func checkRange(origin: SCNVector3, pos: SCNVector3, radius: Float) -> Bool {
        return checkRange(origin: origin.x, pos: pos.x, radius: radius) &&
            checkRange(origin: origin.y, pos: origin.y, radius: radius) &&
            checkRange(origin: origin.z, pos: pos.z, radius: radius)
    }
    
    func checkRange(origin: Float, pos: Float, radius: Float) -> Bool {
        if (origin - radius) ... (origin + radius) ~= pos {
            return true
        }
        return false
    }
    //swiftlint:disable all
    func convertCMToPixel(f: Float) -> Float {
        return (f * 96)/2.54
    }
    func convertPixelToCM(f: Float) -> Float {
        return (f * 2.54)/96
    }
    
    func checkRange(tap: CGPoint, position: CGPoint, radius: CGFloat) -> Bool {
        if (position.x - radius) ... (position.x + radius) ~= tap.x && (position.y - radius) ... (position.y + radius) ~= tap.y {
            return true
        }
        return false
    }
    
    func checkTap(tap: CGPoint, radius: Float) -> SCNNode? {
        let radiusPixel = convertCMToPixel(f: radius)
        for node in visibleNodesPosition {
            if checkRange(tap: tap, position: node.value, radius: CGFloat(radiusPixel)) {
                return node.key
            }
        }
        return nil
    }
    
    
    func checkRadiusBasedOnDistance(position: CGPoint, incident: Incident) -> Float? {
        guard let distance = distanceIncidentNodeCamera(incident: incident) else {
            return nil
        }
        
        switch distance {
        case 0..<5.0:
            return 5.0
        case 5.0..<10.0:
            return 4.0
        case 10.0..<20.0:
            return 3.0
        case 20.0..<50.0:
            return 2.0
        case 50.0..<100.0:
            return 1.5
        default:
            return 1.0
        }
        
    }
}
