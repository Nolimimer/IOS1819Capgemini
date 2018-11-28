//
//  Utilities.swift
//  ios1819capgemini
//
//  Created by MembrainDev on 27.11.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

import Foundation
import ARKit


extension CGImagePropertyOrientation {
    init(_ deviceOrientation: UIDeviceOrientation) {
        switch deviceOrientation {
        case .portraitUpsideDown: self = .left
        case .landscapeLeft: self = .up
        case .landscapeRight: self = .down
        default: self = .right
        }
    }
}
