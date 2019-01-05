//
//  ARViewControllerDamageDetectionExtension.swift
//  ios1819capgemini
//
//  Created by Minh Tran on 05.01.19.
//  Copyright © 2019 TUM LS1. All rights reserved.
//

import Foundation
import ARKit
import Vision
import SceneKit
extension ARViewController {
    
    /*
     returns true if there is a node in a certain radius from the coordinate
     */
    func calculateNodesInRadius(coordinate: CGPoint, radius: CGFloat) -> Bool {
        for incident in automaticallyDetectedIncidents {
            if incident.x.distance(to: coordinate.x) < radius || incident.y.distance(to: coordinate.y) < radius {
                return false
            }
        }
        return true
    }
    
    func sigmoid(_ val: Double) -> Double {
        return 1.0 / (1.0 + exp(-val))
    }
    
    // Create shape layers for the bounding boxes.
    func setupBoxes() {
        for _ in 0..<numBoxes {
            let box = BoundingBox()
            box.addToLayer(sceneView.layer)
            self.boundingBoxes.append(box)
        }
    }
    
    func configureLighting() {
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    // Handle completion of the Vision request and choose results to display.
    /// - Tag: ProcessClassifications
    func processClassifications(for request: VNRequest, error: Error?) -> [Prediction]? {
        guard let results = request.results as? [VNCoreMLFeatureValueObservation], results.count == 2 else {
            return nil
        }
        
        guard let boxPredictions = results[1].featureValue.multiArrayValue,
            let classPredictions = results[0].featureValue.multiArrayValue else {
                return nil
        }
        
        let predictions = self.ssdPostProcessor.postprocess(boxPredictions: boxPredictions, classPredictions: classPredictions)
        return predictions
    }
    // Draw Boxes which indicate if a sticker has been detected
    //swiftlint:disable function_body_length
    func drawBoxes(predictions: [Prediction]) {
        for (index, prediction) in predictions.enumerated() {
            if let classNames = self.ssdPostProcessor.classNames {
                statusViewController.showMessage("\(classNames[prediction.detectedClass]) has been detected", autoHide: true)
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
                if detectedObjectNode != nil {
                    self.boundingBoxes[index].show(frame: rect,
                                                   label: textLabel,
                                                   color: UIColor.green,
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
                        let incident = Incident (type: .scratch,
                                                 description: "length : \(formattedLength)cm width : \(formattedWidth)cm",
                                                 coordinate: Coordinate(vector: coordinates))
                        DataHandler.incidents.append(incident)
                        sphereNode.runAction(imageHighlightAction)
                        sphereNode.name = "\(incident.identifier)"
                        self.scene.rootNode.addChildNode(sphereNode)
                        nodes.append(sphereNode)
                        do {
                            let data = try JSONEncoder().encode(incident)
                            self.multipeerSession.sendToAllPeers(data)
                            statusViewController.showMessage("automatically detected incident has been sent", autoHide: true)
                        } catch _ {
                            print("Encoding DataHandler.incidents failed")
                        }
                    }
                }
                //cameraView.layer.addSublayer(self.boundingBoxes[index].shapeLayer)
            }
        }
        for index in predictions.count..<self.numBoxes {
            self.boundingBoxes[index].hide()
        }
    }
    
}
