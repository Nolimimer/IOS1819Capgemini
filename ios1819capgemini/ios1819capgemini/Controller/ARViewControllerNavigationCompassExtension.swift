//
//  ARViewControllerNavigationCompassExtension.swift
//  ios1819capgemini
//
//  Created by Minh Tran on 29.12.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

import Foundation
import ARKit


    /*
    currently not working b/c x and y axis and therefore the transformed incident node position change when rotating the device
    */
extension ARViewController {
    /*
     calculates the angle of the arrow label relative to the incident node. Method does not take user rotation into play.
     possible solutions:
     1. temporarily saving the last projected incident node coordinate and check if a drastic change in position has been made. If so, use the inverse function of arctan2 to calculate the angle from the different side.
     2. give suggestion on how to rotate the device using eulerAngles (eulerAngles from the node creators perspective will have to be saved) before providing an arrow on where to look
     3. use spritekitscene to project the incident node to the scene instead of to user's screen. Calculate the angle based on the user screen and the sprite kit scene
     4. use 3D arrow to avoid projecting the point. 
    */
    func angleIncidentPOV (incident: Incident?) -> Float? {
        guard let incident = incident else {
            return nil
        }
        let incidentNode = nodes.first(where: { $0.name == String(incident.identifier) })
        guard let vector = incidentNode?.presentation.worldPosition else {
            return nil
        }
        let incidentProjected = self.sceneView.projectPoint(vector)
//        print("incident projected :\(incidentProjected)")
        let arrowX = arrowLabel.frame.midX
        let arrowY = arrowLabel.frame.midY
        let xDiff = incidentProjected.x - Float(arrowX)
        let yDiff = incidentProjected.y - Float(arrowY)
        arrowLabel.isHidden = false
        let angle = atan2f(yDiff, xDiff)
        return angle - Float(90.0.degreesToRadians)
    }
    
    func setArrow(angle: Float, incident: Incident?, for trackingState: ARCamera.TrackingState) {
        guard var distanceCamera = distanceCameraNode(incident: incident), let incident = incident else {
            return
        }
        let formatter = NumberFormatter()
        let incidentNode = nodes.first(where: { $0.name == String(incident.identifier) })
        formatter.minimumFractionDigits = 2
        distanceCamera *= 100
        guard let node = incidentNode, let distance = formatter.string(from: NSNumber(value: distanceCamera)) else {
            return
        }
        if nodeVisibleToUser(node: node) {
            arrowLabel.isHidden = true
            statusViewController.showMessage("Incident is \(distance)cm away from your device")
            return
        }
        statusViewController.showTrackingQualityInfo(for: trackingState, autoHide: true)
        arrowLabel.isHidden = false
        arrowLabel.transform = CGAffineTransform(rotationAngle: CGFloat(angle) - CGFloat(180.0.degreesToRadians))
    }
}
extension FloatingPoint {
    var degreesToRadians: Self { return self * .pi / 180 }
    var radiansToDegrees: Self { return self * 180 / .pi }
}
