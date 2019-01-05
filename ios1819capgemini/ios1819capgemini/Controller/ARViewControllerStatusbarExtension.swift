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
        
//    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
//        statusViewController.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)
//
//        switch camera.trackingState {
//        case .notAvailable, .limited:
//            statusViewController.escalateFeedback(for: camera.trackingState, inSeconds: 6.0)
//        case .normal:
//            statusViewController.cancelScheduledMessage(for: .trackingStateEscalation)
//        }
//    }
    func updateStatus(for frame: ARFrame, trackingState: ARCamera.TrackingState) {
        // Update the UI to provide feedback on the state of the AR experience.
        let message: String
        
        switch trackingState {
        case .normal where frame.anchors.isEmpty && multipeerSession.connectedPeers.isEmpty:
            // No planes detected; provide instructions for this app's AR interactions.
            message = "Move around to map the environment, or wait to join a shared session."
            
        case .normal where !multipeerSession.connectedPeers.isEmpty && mapProvider == nil:
            let peerNames = multipeerSession.connectedPeers.map({ $0.displayName }).joined(separator: ", ")
            message = "Connected with \(peerNames)."
            
        case .notAvailable:
            message = "Tracking unavailable."
            
        case .limited(.excessiveMotion):
            message = "Tracking limited - Move the device more slowly."
            
        case .limited(.insufficientFeatures):
            message = "Tracking limited - Point the device at an area with visible surface detail, or improve lighting conditions."
            
        case .limited(.initializing) where mapProvider != nil,
             .limited(.relocalizing) where mapProvider != nil:
            guard let mapProvider = mapProvider else {
                return
            }
            message = "Received map from \(mapProvider.displayName)."
            
        case .limited(.relocalizing):
            message = "Resuming session — move to where you were when the session was interrupted."
            
        case .limited(.initializing):
            message = "Initializing AR session."
            
        default:
            // No feedback needed when tracking is normal and planes are visible.
            // (Nor when in unreachable limited-tracking states.)
            message = ""
            
        }
        statusViewController.showMessage(message, autoHide: true)
    }
}
