//
//  StatusViewController.swift
//  ios1819capgemini
//
//  Created by Minh Tran on 21.12.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

import Foundation
import ARKit

//swiftlint:disable all
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
    
    @IBAction func resetButtonPressed(_ sender: Any) {
        ARViewController.resetButtonPressed = true
        
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
            if let recommendation = trackingState.recommendation {
                message.append(": \(recommendation)")
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
                       delay: 0, options: [.beginFromCurrentState],
                       animations: {
            self.messagePanel.alpha = hide ? 0 : 1
        }, completion: nil)
    }
}
