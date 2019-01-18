//
//  ARViewControllerDamageDetectionExtension.swift
//  ios1819capgemini
//
//  Created by Minh Tran on 13.01.19.
//  Copyright © 2019 TUM LS1. All rights reserved.
//

import Foundation
import ARKit


extension ARViewController {
    
    func hideBoxes() {
        for box in boundingBoxes {
            box.hide()
        }
    }
    
    // Create shape layers for the bounding boxes.
    func setupBoxes() {
        for _ in 0..<numBoxes {
            let box = BoundingBox()
            box.addToLayer(sceneView.layer)
            self.boundingBoxes.append(box)
        }
    }
    
    // Draw Boxes which indicate if a sticker has been detected
    // swiftlint:disable function_body_length
    func drawBoxes(predictions: [Prediction]) {
        for (index, prediction) in predictions.enumerated() {
            if let classNames = self.ssdPostProcessor.classNames {
                //print("Class: \(classNames[prediction.detectedClass])")
                
                let textColor: UIColor
                let textLabel = String(format: "%.2f - %@",
                                       self.sigmoid(prediction.score),
                                       classNames[prediction.detectedClass])
                
                textColor = UIColor.black
                guard let imgWidth = self.screenWidth,
                    let imgHeight = self.screenHeight else {
                        return
                }
                
                let rect = prediction.finalPrediction.toCGRect(imgWidth: imgWidth,
                                                               imgHeight: imgWidth,
                                                               xOffset: 0,
                                                               yOffset: (imgHeight - imgWidth) / 2)
                //uncomment if boxes should only appear after object has been detected
                if isDetecting {
                    self.boundingBoxes[index].show(frame: rect,
                                                   label: textLabel,
                                                   color: SSDPostProcessor.getColor(forName: classNames[prediction.detectedClass]),
                                                   textColor: textColor)
                    let position = CGPoint(x: rect.midX,
                                           y: rect.midY)
                    let hitTestResult = sceneView.hitTest(position, types: .featurePoint)
                    guard let hitTest = hitTestResult.first else {
                        return
                    }
                    if sigmoid(prediction.score) > 0.80 && calculateNodesInRadius(coordinate: position, radius: 40) {
                        let tmp = SCNVector3(x: (hitTest.worldTransform.columns.3.x),
                                             y: (hitTest.worldTransform.columns.3.y),
                                             z: (hitTest.worldTransform.columns.3.z))
                        let length = rect.maxY - rect.minY
                        let width = rect.maxX - rect.minX
                        let formatter = NumberFormatter()
                        formatter.maximumFractionDigits = 2
                        let lengthCM = (length * 2.54) / 96
                        let widthCM = (width * 2.54) / 96
                        guard let formattedLength = formatter.string(from: NSNumber(value: Float(lengthCM))) else {
                            return
                        }
                        guard let formattedWidth = formatter.string(from: NSNumber(value: Float(widthCM))) else {
                            return
                        }
                        automaticallyDetectedIncidents.append(position)
                        let sphere = SCNSphere(radius: 0.015)
                        let materialSphere = SCNMaterial()
                        materialSphere.diffuse.contents = UIColor(red: 0.0,
                                                                  green: 0.0,
                                                                  blue: 1.0,
                                                                  alpha: CGFloat(Float(sigmoid(prediction.score))))
                        sphere.materials = [materialSphere]
                        let sphereNode = SCNNode(geometry: sphere)
                        sphereNode.position = tmp
                        let coordinates = sceneView.scene.rootNode.convertPosition(
                            SCNVector3(hitTest.worldTransform.columns.3.x,
                                       hitTest.worldTransform.columns.3.y,
                                       hitTest.worldTransform.columns.3.z),
                            to: self.detectedObjectNode)
                        
                        let incident = Incident (type: IncidentType(rawValue: classNames[prediction.detectedClass]) ?? .unknown,
                                                 description: "length : \(formattedLength)cm width : \(formattedWidth)cm",
                                                 coordinate: Coordinate(vector: coordinates))
                        incident.automaticallyDetected = true
                        self.selectedCarPart?.incidents.append(incident)
                        DataHandler.incidents.append(incident)
                        sphereNode.runAction(imageHighlightAction)
                        sphereNode.name = "\(incident.identifier)"
                        self.scene.rootNode.addChildNode(sphereNode)
                        nodes.append(sphereNode)
                        sendIncident(incident: incident)
                    }
                    return
                }
                //cameraView.layer.addSublayer(self.boundingBoxes[index].shapeLayer)
            }
        }
        for index in predictions.count..<self.numBoxes {
            self.boundingBoxes[index].hide()
        }
    }
    
    
    func sigmoid(_ val: Double) -> Double {
        return 1.0 / (1.0 + exp(-val))
    }
    
    func configureLighting() {
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
}
