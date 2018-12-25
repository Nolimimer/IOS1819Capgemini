/*
 Copyright © 2018 Apple Inc.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
Abstract:
Presentation information about the current tracking state.
*/

import Foundation
import ARKit

extension ARCamera.TrackingState {
    var presentationString: String {
        switch self {
        case .notAvailable:
            return "ARKit tracking UNAVAILABLE"
        case .normal:
            return "ARKit tracking NORMAL"
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                return "ARKit tracking LIMITED: Excessive motion"
            case .insufficientFeatures:
                return "ARKit tracking LIMITED: Low detail"
            case .initializing:
                return "ARKit is initializing"
            case .relocalizing:
                return "ARKit is relocalizing"
            }
        }
    }
    
    var recommendation: String? {
        switch self {
        case .limited(.excessiveMotion):
            return "Try slowing down your movement, or reset the session."
        case .limited(.insufficientFeatures):
            return "Try pointing at a flat surface, or reset the session."
        case .limited(.initializing):
            return "Try moving left or right, or reset the session."
        case .limited(.relocalizing):
            return "Try returning to the location where you left off."
        default:
            return nil
        }
    }
}
