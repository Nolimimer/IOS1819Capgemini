/*
 Copyright © 2018 Apple Inc.
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
Abstract:
A simple visualiation of a 3D bounding box, used when testing detection of a scanned object.
*/

import Foundation
import ARKit

class DetectedBoundingBox: SCNNode {
    
    init(points: [float3], scale: CGFloat, color: UIColor = .appYellow) {
        super.init()
        
        var localMin = float3(Float.greatestFiniteMagnitude)
        var localMax = float3(-Float.greatestFiniteMagnitude)
        
        for point in points {
            localMin = min(localMin, point)
            localMax = max(localMax, point)
        }
        
        self.simdPosition += (localMax + localMin) / 2
        let extent = localMax - localMin
        let wireframe = Wireframe(extent: extent, color: color, scale: scale)
        self.addChildNode(wireframe)
    }
    //swiftlint:disable unavailable_function
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
