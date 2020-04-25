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
            return "UNAVAILABLE"
        case .normal:
            return "NORMAL"
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                return "EXCESSIVE MOTION"
            case .insufficientFeatures:
                return "LOW DETAIL"
            case .initializing:
                return "INITIALIZING"
            case .relocalizing:
                return "RELOCALIZING"
            }
        }
    }
    
    var recommendation: String? {
        switch self {
        case .limited(.excessiveMotion):
            return ""
        case .limited(.insufficientFeatures):
            return ""
        case .limited(.initializing):
            return ""
        case .limited(.relocalizing):
            return ""
        default:
            return nil
        }
    }
}
