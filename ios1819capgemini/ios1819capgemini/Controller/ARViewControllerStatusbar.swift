//
//  ARViewController+ARSessionDelegate.swift
//  ios1819capgemini
//
//  Created by Minh Tran on 21.12.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

import Foundation
import ARKit
extension ARViewController {
        
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        statusViewController.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)
        if camera.trackingState.presentationString == "RELOCALIZING" || camera.trackingState.presentationString == "INITIALIZING" {
            for node in nodes {
                node.opacity = 0
            }
            self.scene.rootNode.childNode(withName: "info-plane", recursively: true)?.opacity = 0
        } else {
            for node in nodes {
                node.opacity = 1
            }
            self.scene.rootNode.childNode(withName: "info-plane", recursively: true)?.opacity = 1
        }
        switch camera.trackingState {
        case .notAvailable, .limited:
            statusViewController.escalateFeedback(for: camera.trackingState, inSeconds: 6.0)
        case .normal:
            statusViewController.cancelScheduledMessage(for: .trackingStateEscalation)
        }
    }
}
