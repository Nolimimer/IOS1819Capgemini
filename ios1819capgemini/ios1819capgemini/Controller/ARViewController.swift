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


// Stores all the nodes added to the scene
var nodes = [SCNNode]()
// swiftlint:disable all
// MARK: - ARViewController
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
    var showDebugOption = true
    private var automaticallyDetectedIncidents = [CGPoint]()
    private var detected = false
    private var descriptionNode = SKLabelNode(text: "")
    private var anchorLabels = [UUID: String]()
    private var objectAnchor: ARObjectAnchor?
    private var node: SCNNode?
    lazy var statusViewController: StatusViewController = {
        return children.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()

    // The pixel buffer being held for analysis; used to serialize Vision requests.
    private var currentBuffer: CVPixelBuffer?
    // Queue for dispatching vision classification requests
    private let visionQueue = DispatchQueue(label: "com.example.apple-samplecode.ARKitVision.serialVisionQueue")
    
    var imageHighlightAction: SCNAction {
        return .sequence([
            .wait(duration: 0.25),
            .fadeOpacity(to: 0.9, duration: 0.25),
            .fadeOpacity(to: 0.15, duration: 0.25),
            .fadeOpacity(to: 1, duration: 0.25),
            ])
    }
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
        sceneView.debugOptions = [.showFeaturePoints,
                                  .showBoundingBoxes]
        model = try? VNCoreMLModel(for: stickerTest().model)
        
        setupBoxes()
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        sceneView.addGestureRecognizer(gestureRecognizer)
        
        configureLighting()
    }
        override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        screenWidth = Double(size.width)
        screenHeight = Double(size.height)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let config = ARWorldTrackingConfiguration()
        if let detectionObjects = ARReferenceObject.referenceObjects(inGroupNamed: "TestObjects", bundle: Bundle.main) {
            config.detectionObjects = detectionObjects
            sceneView.session.run(config)
        }
    }

    // MARK: ML methods
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
    
    // Create shape layers for the bounding boxes.
    func setupBoxes() {
        for _ in 0..<numBoxes {
            let box = BoundingBox()
            box.addToLayer(sceneView.layer)
            self.boundingBoxes.append(box)
        }
    }
    //swiftlint:disable force_unwrapping
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
    
    // Draw Boxes which indicate if a sticker has been detected
    func drawBoxes(predictions: [Prediction]) {
        
        for (index, prediction) in predictions.enumerated() {
            if let classNames = self.ssdPostProcessor.classNames {
                //print("Class: \(classNames[prediction.detectedClass])")
                
                let textColor: UIColor
                let textLabel = String(format: "%.2f - %@", self.sigmoid(prediction.score),
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
//                if detectedObjectNode != nil {
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
                    if sigmoid(prediction.score) > 0.85 && calculateNodesInRadius(coordinate: position, radius: 20) {
                        let tmp = SCNVector3(x: (hitTest.worldTransform.columns.3.x),
                                             y: (hitTest.worldTransform.columns.3.y),
                                             z: (hitTest.worldTransform.columns.3.z))
                        automaticallyDetectedIncidents.append(position)
                        let sphere = SCNSphere(radius: 0.015)
                        let materialSphere = SCNMaterial()
                        materialSphere.diffuse.contents = UIColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 0.9)
                        sphere.materials = [materialSphere]
                        let sphereNode = SCNNode(geometry: sphere)
                        sphereNode.position = tmp
                        if detectedObjectNode != nil {
                            let coordinates = sceneView.scene.rootNode.convertPosition(
                                SCNVector3(hitTest.worldTransform.columns.3.x,
                                           hitTest.worldTransform.columns.3.y,
                                           hitTest.worldTransform.columns.3.z),
                                to: self.detectedObjectNode)
                            let incident = Incident (type: .unknown,
                                                     description: "",
                                                     coordinate: Coordinate(vector: coordinates))
                            DataHandler.incidents.append(incident)
                        }
                        sphereNode.runAction(imageHighlightAction)
                        self.scene.rootNode.addChildNode(sphereNode)
                        nodes.append(sphereNode)
                    }
//                }
                //cameraView.layer.addSublayer(self.boundingBoxes[index].shapeLayer)
            }
        }
        for index in predictions.count..<self.numBoxes {
            self.boundingBoxes[index].hide()
        }
    }
    /*
     returns true if there is a node in a certain radius from the coordinate
    */
    private func calculateNodesInRadius(coordinate: CGPoint , radius: CGFloat) -> Bool {
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
    
    private func configureLighting() {
        sceneView.autoenablesDefaultLighting = true
        sceneView.automaticallyUpdatesLighting = true
    }
    
    // MARK: AR methods
    /*
     recognizes if the screen has been tapped, creates a new pin and a matching incident if the tapped location is not a pin, otherwise
     opens the detail view for the tapped pin.
     If a new pin is created a screenshot of the location is taken before/after placing the pin.
     */
    @objc func tapped(recognizer: UIGestureRecognizer) {
        if recognizer.state == .ended {
            let location: CGPoint = recognizer.location(in: sceneView)
            let hits = self.sceneView.hitTest(location, options: nil)
            if !hits.isEmpty {
                let tappedNode = hits.first?.node
                guard (tappedNode?.name) != nil else {
                    let touchPosition = recognizer.location(in: sceneView)
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
                            saveImage(image: imageWithoutPin, incident: incident)
                            add3DPin(vectorCoordinate: SCNVector3(hitResult.worldTransform.columns.3.x,
                                                                  hitResult.worldTransform.columns.3.y,
                                                                  hitResult.worldTransform.columns.3.z),
                                     identifier: "\(incident.identifier)" )
                            filter3DPins(identifier: "\(incident.identifier)")
                            let imageWithPin = sceneView.snapshot()
                            saveImage(image: imageWithPin, incident: incident)
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
    //adds a 3D pin to the AR View
    private func add3DPin (vectorCoordinate: SCNVector3, identifier: String) {
                let sphere = SCNSphere(radius: 0.015)
                let materialSphere = SCNMaterial()
                materialSphere.diffuse.contents = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.9)
                sphere.materials = [materialSphere]
                let sphereNode = SCNNode(geometry: sphere)
                sphereNode.name = identifier
                sphereNode.position = vectorCoordinate
                self.scene.rootNode.addChildNode(sphereNode)
                nodes.append(sphereNode)
    }
    
    //adds the info plane which displays the detected object and the number of incidents
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
        let planePosition = SCNVector3(absoluteObjectPosition.x,
                                       absoluteObjectPosition.y + self.objectAnchor!.referenceObject.extent.y,
                                       absoluteObjectPosition.z)
        planeNode.position = planePosition
        let labelNode = SKLabelNode(text: carPart)
        labelNode.fontSize = 40
        labelNode.color = UIColor.black
        labelNode.fontName = "Helvetica-Bold"
        labelNode.position = CGPoint(x: 120, y: 200)
        
        descriptionNode = SKLabelNode(text: "Incidents: \(DataHandler.incidents.count)")
        descriptionNode.fontSize = 30
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
    

    
    //method is automatically executed. scans the AR View for the object which should be detected
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        
        if let objectAnchor = anchor as? ARObjectAnchor {
            
            let notification = UINotificationFeedbackGenerator()
            
            DispatchQueue.main.async {
                notification.notificationOccurred(.success)
            }
            detected = true
            self.node = node
            self.objectAnchor = objectAnchor
            detectedObjectNode = node
            for incident in DataHandler.incidents {
                add3DPin(vectorCoordinate: incident.getCoordinateToVector(), identifier: "\(incident.identifier)")
            }
            addInfoPlane(carPart: objectAnchor.referenceObject.name ?? "Unknown Car Part")
        }
        return node
    }
    
        // MARK: Screenshot methods
    func saveImage(image: UIImage, incident: Incident) {
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        
        let paths = NSSearchPathForDirectoriesInDomains(
            FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentsDirectory = URL(fileURLWithPath: paths[0])
        
        guard let data = image.jpegData(compressionQuality: 0.5) else {
            return
        }
        do {
            let defaults = UserDefaults.standard
            let name = "cARgeminiasset\(defaults.integer(forKey: "AttachedPhotoName")).jpg"
            let path = documentsDirectory.appendingPathComponent(name)
            try data.write(to: path, options: [])
            defaults.set(defaults.integer(forKey: "AttachedPhotoName") + 1, forKey: "AttachedPhotoName")
            incident.addAttachment(attachment: Photo(name: name, photoPath: "\(paths[0])/\(name)"))
        } catch {
            print(error.localizedDescription)
            return
        }
    }
    // Temporarily deletes all the pins except for the pin in the method call from the view and then adds them back again after 1 second
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
    // Temporarily deletes all the pins from the view and then adds them back again after 1 second
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
    
    // MARK: IBAction
    @IBAction func debugButtonPressed(_ sender: UIButton) {
        if showDebugOption {
            showDebugOption = false
            self.sceneView.debugOptions = []
            sender.setTitle("Debug On", for: .normal)
        }
        else {
            showDebugOption = true
            self.sceneView.debugOptions = [.showFeaturePoints, .showBoundingBoxes]
            sender.setTitle("Debug Off", for: .normal)
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
