/*
 Copyright © 2018 Apple Inc.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
Abstract:
A custom rotation gesture reconizer that fires only when a threshold is passed.
*/
import UIKit.UIGestureRecognizerSubclass

class ThresholdRotationGestureRecognizer: UIRotationGestureRecognizer {
    
    /// The threshold after which this gesture is detected.
    private static let threshold: CGFloat = .pi / 15 // (12°)
    
    /// Indicates whether the currently active gesture has exceeeded the threshold.
    private(set) var isThresholdExceeded = false
    
    var previousRotation: CGFloat = 0
    var rotationDelta: CGFloat = 0
    
    /// Observe when the gesture's `state` changes to reset the threshold.
    override var state: UIGestureRecognizer.State {
        didSet {
            switch state {
            case .began, .changed:
                break
            default:
                // Reset threshold check.
                isThresholdExceeded = false
                previousRotation = 0
                rotationDelta = 0
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        
        if isThresholdExceeded {
            rotationDelta = rotation - previousRotation
            previousRotation = rotation
        }
        
        if !isThresholdExceeded && abs(rotation) > ThresholdRotationGestureRecognizer.threshold {
            isThresholdExceeded = true
            previousRotation = rotation
        }
    }
}
