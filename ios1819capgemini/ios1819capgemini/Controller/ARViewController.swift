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
// swiftlint:disable type_body_length
class ARViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {

    // MARK: Stored Instance Properties
    var detectedObjectNode: SCNNode?
    let scene = SCNScene()
    let ssdPostProcessor = SSDPostProcessor(numAnchors: 1917, numClasses: 2)
    var screenHeight: Double?
    var screenWidth: Double?
    let numBoxes = 100
    var boundingBoxes: [BoundingBox] = []
    let multiClass = true
    var model: VNCoreMLModel?
    private var detected = false
    private var descriptionNode = SKLabelNode(text: "")
    private var isDetecting = true
    private var anchorLabels = [UUID: String]()
    private var objectAnchor: ARObjectAnchor?
    private var node: SCNNode?
    // The pixel buffer being held for analysis; used to serialize Vision requests.
    private var currentBuffer: CVPixelBuffer?
    // Queue for dispatching vision classification requests
    private let visionQueue = DispatchQueue(label: "com.example.apple-samplecode.ARKitVision.serialVisionQueue")

    // MARK: IBOutlets
    @IBOutlet private var sceneView: ARSCNView!
    @IBAction private func detectionButtonTapped(_ sender: UIButton) {
        if sender.currentTitle == "Automatic Detection: On" {
        } else {
            sender.setTitle("Automatic Detection: On", for: UIControl.State.normal)
            isDetecting = true
        }
    }
    
    // MARK: Overridden/Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
                
        sceneView.delegate = self
        sceneView.showsStatistics = false
        sceneView.scene = scene

        sceneView.session.delegate = self
        screenWidth = Double(view.frame.width)
        screenHeight = Double(view.frame.height)
        
        sceneView.debugOptions = [.showFeaturePoints]
        
        model = try? VNCoreMLModel(for: stickerTest().model)
        
        setupBoxes()
        // Hook up status view controller callback.
//        statusViewController.restartExperienceHandler = { [unowned self] in
//            self.restartSession()
//        }
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        sceneView.addGestureRecognizer(gestureRecognizer)
        
        configureLighting()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        screenWidth = Double(size.width)
        screenHeight = Double(size.height)
        if UIDevice.current.orientation.isLandscape {
            print("Landscape")
        } else {
            print("Portrait")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let config = ARWorldTrackingConfiguration()
        if let detectionObjects = ARReferenceObject.referenceObjects(inGroupNamed: "TestObjects", bundle: Bundle.main) {
            config.detectionObjects = detectionObjects
            sceneView.session.run(config)
        }
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
        if isDetecting {
            classifyCurrentImage()
        }

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
        //swiftlint:disable force_unwrapping
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
    //swiftlint:enable force_unwrapping
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
                //print("Class: \(classNames[prediction.detectedClass])")
                
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
    
    private func configureLighting() {
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    
    private func add3DPin (vectorCoordinate: SCNVector3, identifier: String) {
        let sphere = SCNSphere(radius: 0.015)
        let materialSphere = SCNMaterial()
        materialSphere.diffuse.contents = UIColor.red
        sphere.materials = [materialSphere]
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.name = identifier
        sphereNode.position = vectorCoordinate
        self.scene.rootNode.addChildNode(sphereNode)
    }
    
    // swiftlint:disable force_unwrapping
    func removeNode (identifier: String) -> Bool {
        if self.scene.rootNode.childNode(withName: identifier, recursively: false) != nil {
            self.scene.rootNode.childNode(withName: identifier, recursively: false)!.removeFromParentNode()
            return true
        }
        return false
    }
    private func filter3DPins (identifier: String) {
        self.scene.rootNode.childNodes.forEach { node in
            if node.name != nil {
                if node.name != identifier {
                    let tmpNode = node
                    self.scene.rootNode.childNode(withName: node.name!, recursively: false)?.removeFromParentNode()
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                        self.scene.rootNode.addChildNode(tmpNode)
                    })
                }
            }
        }
    }
    private func filterAllPins () {
        self.scene.rootNode.childNodes.forEach { node in
            if node.name != nil {
                let tmpNode = node
                    self.scene.rootNode.childNode(withName: node.name!, recursively: false)?.removeFromParentNode()
                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                        self.scene.rootNode.addChildNode(tmpNode)
                    })
            }
        }
    }
    private func addInfoPlane (carPart: String) {
        
        let plane = SCNPlane(width: CGFloat(self.objectAnchor!.referenceObject.extent.x * 0.8),
                             height: CGFloat(self.objectAnchor!.referenceObject.extent.y * 0.3))
        plane.cornerRadius = plane.width / 8
        let spriteKitScene = SKScene(size: CGSize(width: 300, height: 300))
        spriteKitScene.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.8)
        plane.firstMaterial?.diffuse.contents = spriteKitScene
        plane.firstMaterial?.isDoubleSided = true
        plane.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
        let planeNode = SCNNode(geometry: plane)
        let absoluteObjectPosition = objectAnchor!.transform.columns.3
        let planePosition = SCNVector3(absoluteObjectPosition.x, absoluteObjectPosition.y + self.objectAnchor!.referenceObject.extent.y, absoluteObjectPosition.z)
        planeNode.position = planePosition
        let labelNode = SKLabelNode(text: carPart)
        labelNode.fontSize = 40
        labelNode.color = UIColor.black
        labelNode.fontName = "Helvetica-Bold"
        labelNode.position = CGPoint(x: 120, y: 200)
        
        
        descriptionNode = SKLabelNode(text: "Incidents: \(DataHandler.incidents.count)")
        descriptionNode.fontSize = 30
        //swiftlint:disable empty_count
        if DataHandler.incidents.count == 0 {
            descriptionNode.fontColor = UIColor.green
        } else {
            descriptionNode.fontColor = UIColor.red
        }
        descriptionNode.fontName = "Helvetica-Bold"
        descriptionNode.position = CGPoint(x: 120, y: 50)
        spriteKitScene.addChild(descriptionNode)
        spriteKitScene.addChild(labelNode)
        planeNode.constraints = [SCNBillboardConstraint()]

        scene.rootNode.addChildNode(planeNode)
    }
    // swiftlint:enable force_unwrapping
    @objc func tapped(recognizer: UIGestureRecognizer) {
        if recognizer.state == .ended {
            let location: CGPoint = recognizer.location(in: sceneView)
            let hits = self.sceneView.hitTest(location, options: nil)
            if !hits.isEmpty {
                let tappedNode = hits.first?.node
                guard (tappedNode?.name) != nil else {
                    // Get exact position where touch happened on screen of iPhone (2D coordinate)
                    let touchPosition = recognizer.location(in: sceneView)
                    // Conduct a hit test based on a feature point that ARKit detected to find out what 3D point this 2D coordinate relates to
                    let hitTestResult = sceneView.hitTest(touchPosition, types: .featurePoint)
                    
                    if !hitTestResult.isEmpty {
                        guard let hitResult = hitTestResult.first else {
                            return
                        }
                        if detectedObjectNode != nil {
                            let coordinateRelativeToObject = sceneView.scene.rootNode.convertPosition(
                                SCNVector3(hitResult.worldTransform.columns.3.x,
                                           hitResult.worldTransform.columns.3.y,
                                           hitResult.worldTransform.columns.3.z),
                                to: detectedObjectNode)
                            let incident = Incident (type: .unknown,
                                                     description: "New Incident",
                                                     coordinate: Coordinate(vector: coordinateRelativeToObject))
                            filterAllPins()
                            let imageWithoutPin = sceneView.snapshot()
                            saveImage(image: imageWithoutPin)
                            add3DPin(vectorCoordinate: SCNVector3(hitResult.worldTransform.columns.3.x,
                                                                  hitResult.worldTransform.columns.3.y,
                                                                  hitResult.worldTransform.columns.3.z),
                                     identifier: "\(incident.identifier)" )
                            filter3DPins(identifier: "\(incident.identifier)")
                            let imageWithPin = sceneView.snapshot()
                            saveImage(image: imageWithPin)
                            DataHandler.incidents.append(incident)
                            descriptionNode.text = "Incidents : \(DataHandler.incidents.count)"
                        }
                    }
                    return
                }
                self.performSegue(withIdentifier: "ShowDetailSegue", sender: tappedNode)
            }
        }
    }
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        
        if let objectAnchor = anchor as? ARObjectAnchor {
            
            detected = true
            self.node = node
            self.objectAnchor = objectAnchor
            detectedObjectNode = node
            for incident in DataHandler.incidents {
                add3DPin(vectorCoordinate: incident.getCoordinateToVector(), identifier: "\(incident.identifier)")
            }
            addInfoPlane(carPart: objectAnchor.referenceObject.name ?? "Unknown Car Part")
            // swiftlint:disable force_unwrapping

            let alertController = UIAlertController(title: "Object detected",
                                                    message: "\(objectAnchor.referenceObject.name!)",
                                                    preferredStyle: .alert)
            // swiftlint:enable force_unwrapping
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            present(alertController, animated: true)
        }
        return node
    }
    
    func saveImage(image: UIImage) {
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        let paths = NSSearchPathForDirectoriesInDomains(
            FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentsDirectory = URL(fileURLWithPath: paths[0])
        
        guard let data = image.jpegData(compressionQuality: 0.5) else {
            return
        }
        do {
            let defaults = UserDefaults.standard
            try data.write(to: documentsDirectory.appendingPathComponent("cARgeminiasset\(defaults.integer(forKey: "AttachedPhotoName")).jpg"), options: [])
            defaults.set(defaults.integer(forKey: "AttachedPhotoName") + 1, forKey: "AttachedPhotoName")
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    
    // MARK: Overridden/Lifecycle Methods
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "ShowDetailSegue":
            guard let detailVC = (segue.destination as? UINavigationController)?.topViewController as? DetailViewController,
            let pin = sender as? SCNNode,
                let incident = DataHandler.incident(withId: Int(pin.name ?? "") ?? -1) else {
                return
            }
            detailVC.incident = incident
        default :
            return
        }
    }
}

// MARK: Coordinate
struct Coordinate: Codable {
    let pointX: Float
    let pointY: Float
    let pointZ: Float
    
    var description: String {
        return "x: \(pointX), y: \(pointY), z: \(pointZ) "
    }
    
    init(vector: SCNVector3) {
        pointX = vector.x
        pointY = vector.y
        pointZ = vector.z
    }
}
