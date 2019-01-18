//
//  StatusViewController.swift
//  ios1819capgemini
//
//  Created by Minh Tran on 21.12.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

import Foundation
import ARKit

class StatusViewController: UIViewController {
    
    enum MessageType {
        case trackingStateEscalation
        case contentPlacement
        
        static var all: [MessageType] = [
            .trackingStateEscalation,
            .contentPlacement
        ]
    }
    @IBOutlet private weak var messagePanel: UIVisualEffectView!
    
    @IBOutlet private weak var messageLabel: UILabel!
    
    @IBAction private func resetButtonPressed(_ sender: Any) {
        if ARViewController.multiUserEnabled {
            let alert = UIAlertController(title: "Error",
                                          message: "Reset Button can't be pressed if Multi User AR is enabled!",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK",
                                          style: .default,
                                          handler: nil))
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
            return
        }
        let alert = UIAlertController(title: "Reset",
                                      message: "Are you sure you want to reset the app ? This will delete all the scanned objects",
                                      preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: { _ in
            DataHandler.objectsToIncidents.removeAll()
            for car in DataHandler.carParts {
                car.incidents.removeAll()
            }
            DataHandler.incidents = []
            self.removeScans()
            ARViewController.resetButtonPressed = true
            DataHandler.saveToJSON()
            self.dismiss(animated: true, completion: nil)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: { _ in
            self.dismiss(animated: true, completion: nil)
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func removeScans() {
        let fileManager = FileManager.default
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            for file in fileURLs {
                if file.lastPathComponent.hasSuffix(".arobject") {
                    try fileManager.removeItem(at: file.absoluteURL)
                }
            }
        } catch {
            print("Error loading custom scans")
        }
    }
    
    @IBAction private func sendIncidentsButtonPressed(_ sender: Any) {
        ARViewController.sendIncidentButtonPressed = true
    }
    
    
    private let displayDuration: TimeInterval = 3
    private var messageHideTimer: Timer?
    
    private var timers: [MessageType: Timer] = [:]
    
    
    func showMessage(_ text: String, autoHide: Bool = false) {
        messageHideTimer?.invalidate()
        
        messageLabel.text = text
        
        setMessageHidden(false, animated: true)
        
        if autoHide {
            messageHideTimer = Timer.scheduledTimer(withTimeInterval: displayDuration, repeats: false, block: { [weak self] _ in
                self?.setMessageHidden(true, animated: true)
            })
        }
    }
    
    func scheduleMessage(_ text: String, inSeconds seconds: TimeInterval, messageType: MessageType) {
        cancelScheduledMessage(for: messageType)
        
        let timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false, block: { [weak self] timer in
            self?.showMessage(text)
            timer.invalidate()
        })
        
        timers[messageType] = timer
    }
    
    func cancelScheduledMessage(for messageType: MessageType) {
        timers[messageType]?.invalidate()
        timers[messageType] = nil
    }
    
    func cancelAllScheduledMessages() {
        for messageType in MessageType.all {
            cancelScheduledMessage(for: messageType)
        }
    }
    
    func showTrackingQualityInfo(for trackingState: ARCamera.TrackingState, autoHide: Bool) {
        showMessage(trackingState.presentationString, autoHide: autoHide)
    }
    
    func escalateFeedback(for trackingState: ARCamera.TrackingState, inSeconds seconds: TimeInterval) {
        cancelScheduledMessage(for: .trackingStateEscalation)
        
        let timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false, block: { [unowned self] _ in
            self.cancelScheduledMessage(for: .trackingStateEscalation)
            
            var message = trackingState.presentationString
            if trackingState.recommendation != nil {
                message.append("")
            }
            
            self.showMessage(message, autoHide: false)
        })
        
        timers[.trackingStateEscalation] = timer
    }

    
    private func setMessageHidden(_ hide: Bool, animated: Bool) {
        messagePanel.isHidden = false
        
        guard animated else {
            messagePanel.alpha = hide ? 0 : 1
            return
        }
        
        UIView.animate(withDuration: 0.2,
                       delay: 0,
                       options: [.beginFromCurrentState],
                       animations: { self.messagePanel.alpha = hide ? 0 : 1 },
                       completion: nil)
    }
}
