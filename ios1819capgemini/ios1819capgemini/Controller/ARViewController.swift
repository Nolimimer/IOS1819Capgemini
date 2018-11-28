//
//  ViewController.swift
//  ios1819capgemini
//
//  Created by RMMM on 06.11.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

// MARK: Imports
import UIKit
import ARKit
import SceneKit
import Vision

// MARK: - ARViewController
class ARViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    // MARK: Stored Instance Properties
    //for AR
    var objectAnchorAbsolute = simd_float4(0,0,0,0)
    var coordinatesPin = [Coordinate(pointX: 0.039081514, pointY: 0.07508006, pointZ: 0.00025102496),
                          Coordinate(pointX: 0.039081514, pointY: 0.07508006, pointZ: 0.00025102496),
                          Coordinate(pointX: 0.17503417, pointY: -0.009129599, pointZ: 0.14398605),
                          Coordinate(pointX: -0.032168947, pointY: 0.023964524, pointZ: 0.011013627),
                          Coordinate(pointX: -0.29854614, pointY: -0.0061006695, pointZ: -0.070008695)]
    
    final let scene = SCNScene()
    let ssdPostProcessor = SSDPostProcessor(numAnchors: 1917, numClasses: 2)
    var screenHeight: Double?
    var screenWidth: Double?
    let semaphore = DispatchSemaphore(value: 1)
    let numBoxes = 100
    var boundingBoxes: [BoundingBox] = []
    let multiClass = true
    var model: VNCoreMLModel?
    private var anchorLabels = [UUID: String]()
    // The pixel buffer being held for analysis; used to serialize Vision requests.
    private var currentBuffer: CVPixelBuffer?
    // Queue for dispatching vision classification requests
    private let visionQueue = DispatchQueue(label: "com.example.apple-samplecode.ARKitVision.serialVisionQueue")

    // MARK: IBOutlets
    @IBOutlet private var sceneView: ARSCNView!
    
    // MARK: Overridden/Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.showsStatistics = false
        sceneView.scene = scene
        
        sceneView.session.delegate = self
        screenWidth = Double(view.frame.width)
        screenHeight = Double(view.frame.height)
        
        model = try? VNCoreMLModel(for: StickerDetector().model)
        
        setupBoxes()
        // Hook up status view controller callback.
//        statusViewController.restartExperienceHandler = { [unowned self] in
//            self.restartSession()
//        }
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        sceneView.addGestureRecognizer(gestureRecognizer)
        
        configureLighting()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let config = ARWorldTrackingConfiguration()
        config.detectionObjects = ARReferenceObject.referenceObjects(inGroupNamed: "TestObjects", bundle: Bundle.main)!
        sceneView.session.run(config)
    }


    // MARK: Object Detection Functions
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Do not enqueue other buffers for processing while another Vision task is still running.
        // The camera stream has only a finite amount of buffers available; holding too many buffers for analysis would starve the camera.
        guard currentBuffer == nil, case .normal = frame.camera.trackingState else {
            return
        }
        // Retain the image buffer for Vision processing.
        self.currentBuffer = frame.capturedImage
        classifyCurrentImage()
    }
    
    func setupBoxes() {
        // Create shape layers for the bounding boxes.
        for _ in 0..<numBoxes {
            let box = BoundingBox()
            box.addToLayer(sceneView.layer)
            self.boundingBoxes.append(box)
        }
    }
    
    
    /// - Tag: ClassificationRequest
    private lazy var classificationRequest: VNCoreMLRequest = {
    
        let request = VNCoreMLRequest(model: model!, completionHandler: { [weak self] request, error in
            //self?.processClassifications(for: request, error: error)
            guard let predictions = self?.processClassifications(for: request, error: error) else {
                return
            }
            DispatchQueue.main.async {
                self?.drawBoxes(predictions: predictions)
            }
        })
        // Crop input images to square area at center, matching the way the ML model was trained.
        request.imageCropAndScaleOption = .centerCrop
        // Use CPU for Vision processing to ensure that there are adequate GPU resources for rendering.
        request.usesCPUOnly = true
        
        return request
    }()
    
    // Run the Vision+ML classifier on the current image buffer.
    /// - Tag: ClassifyCurrentImage
    private func classifyCurrentImage() {
        // Most computer vision tasks are not rotation agnostic so it is important to pass in the orientation of the image with respect to device.
        let orientation = CGImagePropertyOrientation(UIDevice.current.orientation)
        
        guard let cvPixelBuffer = currentBuffer else {
            return
        }
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: cvPixelBuffer, orientation: orientation)
        visionQueue.async {
            do {
                // Release the pixel buffer when done, allowing the next buffer to be processed.
                defer { self.currentBuffer = nil }
                try requestHandler.perform([self.classificationRequest])
            } catch {
                print("Error: Vision request failed with error \"\(error)\"")
            }
        }
    }
    
    // Handle completion of the Vision request and choose results to display.
    /// - Tag: ProcessClassifications
    private func processClassifications(for request: VNRequest, error: Error?) -> [Prediction]? {
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
    
    func drawBoxes(predictions: [Prediction]) {
        
        for (index, prediction) in predictions.enumerated() {
            if let classNames = self.ssdPostProcessor.classNames {
                print("Class: \(classNames[prediction.detectedClass])")
                
                let textColor: UIColor
                let textLabel = String(format: "%.2f - %@", self.sigmoid(prediction.score), classNames[prediction.detectedClass])
                
                textColor = UIColor.black
                guard let imgWidth = self.screenWidth,
                    let imgHeight = self.screenHeight else {
                        return
                }
                
                let rect = prediction.finalPrediction.toCGRect(imgWidth: imgWidth,
                                                               imgHeight: imgWidth,
                                                               xOffset: 0,
                                                               yOffset: (imgHeight - imgWidth) / 2)
                self.boundingBoxes[index].show(frame: rect,
                                               label: textLabel,
                                               color: UIColor.green,
                                               textColor: textColor)
                
                boundingBoxes[index].addToLayer(sceneView.layer)
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
    
    private func clipToObject (pinReferenceX: Float, pinReferenceY: Float, pinReferenceZ: Float) {
        coordinatesPin.append( Coordinate(pointX: pinReferenceX - objectAnchorAbsolute.x,
                                          pointY: pinReferenceY - objectAnchorAbsolute.y,
                                          pointZ: pinReferenceZ - objectAnchorAbsolute.z))
        print("relative coordinates:")
        print(coordinatesPin)
    }
    private func loadPin (toPlace: Coordinate, objectAnchor: ARObjectAnchor) -> SCNNode {
        let planeGeometry = SCNPlane(width: 0.1, height: 0.2)
        let material = SCNMaterial()
        material.diffuse.contents = UIImage(named: "pin")
        planeGeometry.materials = [material]
        planeGeometry.firstMaterial?.isDoubleSided = true
        
        let pinNode = SCNNode(geometry: planeGeometry)
        pinNode.name = "pin node"
        pinNode.position = SCNVector3Make(toPlace.pointX + objectAnchor.referenceObject.center.x,
                                          toPlace.pointY + objectAnchor.referenceObject.center.y,
                                          toPlace.pointZ + objectAnchor.referenceObject.center.z)
        
        sceneView.scene.rootNode.addChildNode(pinNode)
        print("relative Koordinate: ")
        print(toPlace.pointX)
        print(toPlace.pointY)
        print(toPlace.pointZ)
        print("Neue absolute Koordinate:")
        print(toPlace.pointX + objectAnchor.referenceObject.center.x)
        print(toPlace.pointY + objectAnchor.referenceObject.center.y)
        print(toPlace.pointZ + objectAnchor.referenceObject.center.z)
        return pinNode
    }
    private func configureLighting() {
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    
    private func add3DPin (x: Float, y: Float, z: Float) {
        let sphere = SCNSphere(radius: 0.01)
        let materialSphere = SCNMaterial()
        materialSphere.diffuse.contents = UIImage(named: "three_notes")
        sphere.materials = [materialSphere]
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.name = "sphere"
        sphereNode.position = SCNVector3(x, y, z)
        sceneView.scene.rootNode.addChildNode(sphereNode)
    }
    @objc func tapped(recognizer :UIGestureRecognizer) {
        
        if recognizer.state == .ended {
            let location: CGPoint = recognizer.location(in: sceneView)
            let hits = self.sceneView.hitTest(location, options: nil)
            if !hits.isEmpty{
                print("node detected.")
                let tappedNode = hits.first?.node
                guard let name = tappedNode?.name else{
                    print("no name node")
                    // Get exact position where touch happened on screen of iPhone (2D coordinate)
                    let touchPosition = recognizer.location(in: sceneView)
                    
                    // Conduct a hit test based on a feature point that ARKit detected to find out what 3D point this 2D coordinate relates to
                    let hitTestResult = sceneView.hitTest(touchPosition, types: .featurePoint)
                    
                    if !hitTestResult.isEmpty {
                        guard let hitResult = hitTestResult.first else {
                            return
                        }
                        
                        add3DPin(x: hitResult.worldTransform.columns.3.x,
                                 y: hitResult.worldTransform.columns.3.y,
                                 z: hitResult.worldTransform.columns.3.z)
                        
                        //                         addPin(x: hitResult.worldTransform.columns.3.x,
                        //                               y: hitResult.worldTransform.columns.3.y,
                        //                               z: hitResult.worldTransform.columns.3.z)
                        
                        print("tap coordinate \(hitResult.worldTransform.columns.3)")
                        clipToObject(pinReferenceX: hitResult.worldTransform.columns.3.x, pinReferenceY: hitResult.worldTransform.columns.3.y, pinReferenceZ: hitResult.worldTransform.columns.3.z)
                    }
                    return
                }
                print(name)
            }
        }
    }
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        print("renderer() aufgerufen")
        
        let node = SCNNode()
        
        if let objectAnchor = anchor as? ARObjectAnchor {
            
            objectAnchorAbsolute = objectAnchor.transform.columns.3
            print("definitely the absolute position of the chair anchor \(objectAnchorAbsolute)")
            //Maybe we should consider this method for easier computations. sceneView.session.setWorldOrigin(relativeTransform: point)
            
            for pin in coordinatesPin {
                node.addChildNode(loadPin(toPlace: pin, objectAnchor: objectAnchor))
            }
            let alert = UIAlertController(title: "Object detected", message: "\(objectAnchor.referenceObject.name ?? "no name")", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
            print("detected object anchor absolute position. x: \(objectAnchorAbsolute.x), y: \(objectAnchorAbsolute.y), x: \(objectAnchorAbsolute.z)")
        }
        return node
    }
}

// MARK: Coordinate
struct Coordinate {
    var pointX: Float
    var pointY: Float
    var pointZ: Float
    
    var description: String {
        return "x: \(pointX), y: \(pointY), z: \(pointZ) "
    }
}
