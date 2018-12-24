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

//swiftlint:disable all
// Stores all the nodes added to the scene
var nodes = [SCNNode]()

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
        
        sceneView.debugOptions = [.showFeaturePoints]
        sceneView.session.delegate = self
        screenWidth = Double(view.frame.width)
        screenHeight = Double(view.frame.height)
        
        model = try? VNCoreMLModel(for: stickerTest().model)
        
        setupBoxes()
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        sceneView.addGestureRecognizer(gestureRecognizer)
        configureLighting()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let config = ARWorldTrackingConfiguration()
        if let detectionObjects = ARReferenceObject.referenceObjects(inGroupNamed: "TestObjects", bundle: Bundle.main) {
            config.detectionObjects = detectionObjects
            sceneView.session.run(config)
        }
    }

    // MARK: AR Kit methods
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Do not enqueue other buffers for processing while another Vision task is still running.
        // The camera stream has only a finite amount of buffers available; holding too many buffers for analysis would starve the camera.
        guard currentBuffer == nil, case .normal = frame.camera.trackingState else {
            return
        }
        let closestIncident = closestOpenIncident()
        if calculateNodeDistanceVectorToCamera(incident: closestIncident) != nil && closestIncident != nil {
            print("\(closestIncident!.identifier)  \(String(describing: calculateNodeDistanceVectorToCamera(incident: closestIncident)))")
        } else {
            print("no closest incident found")
        }
        
        // Retain the image buffer for Vision processing.
        self.currentBuffer = frame.capturedImage
        if isDetecting {
            classifyCurrentImage()
        }
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
    
    // Create shape layers for the bounding boxes.
    func setupBoxes() {
        for _ in 0..<numBoxes {
            let box = BoundingBox()
            box.addToLayer(sceneView.layer)
            self.boundingBoxes.append(box)
        }
    }
    /// - Tag: ClassificationRequest
    private lazy var classificationRequest: VNCoreMLRequest = {
        
        //swiftlint:disable force_wrapping
        let request = VNCoreMLRequest(model: model!, completionHandler: { [weak self] request, error in
            //self?.processClassifications(for: request, error: error)
            guard let predictions = self?.processClassifications(for: request, error: error) else {
                return
            }
            DispatchQueue.main.async {
                self?.drawBoxes(predictions: predictions)
            }
        })
        //swiftlint:enable force_wrapping
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
                if detectedObjectNode != nil {
                    self.boundingBoxes[index].show(frame: rect,
                                                   label: textLabel,
                                                   color: UIColor.green,
                                                   textColor: textColor)
                }
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
    
    // MARK: AR methods
    
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
        
        guard let objectAnchor = self.objectAnchor else {
            return
        }
        let plane = SCNPlane(width: CGFloat(objectAnchor.referenceObject.extent.x * 0.8),
                             height: CGFloat(objectAnchor.referenceObject.extent.y * 0.3))
        plane.cornerRadius = plane.width / 8
        let spriteKitScene = SKScene(size: CGSize(width: 300, height: 300))
        spriteKitScene.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.8)
        plane.firstMaterial?.diffuse.contents = spriteKitScene
        plane.firstMaterial?.isDoubleSided = true
        plane.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
        let planeNode = SCNNode(geometry: plane)
        let absoluteObjectPosition = objectAnchor.transform.columns.3
        let planePosition = SCNVector3(absoluteObjectPosition.x,
                                       absoluteObjectPosition.y + objectAnchor.referenceObject.extent.y,
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
                        //if detectedObjectNode != nil {
                            let coordinateRelativeToObject = sceneView.scene.rootNode.convertPosition(
                                SCNVector3(hitResult.worldTransform.columns.3.x,
                                           hitResult.worldTransform.columns.3.y,
                                           hitResult.worldTransform.columns.3.z),
                                to: detectedObjectNode)
                            let incident = Incident (type: .unknown,
                                                     description: "New Incident",
                                                     coordinate: Coordinate(vector: coordinateRelativeToObject)
                                                     )
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
                        //}
                    }
                    return
                }
                self.performSegue(withIdentifier: "ShowDetailSegue", sender: tappedNode)
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
    
    // MARK: Helper methods
    
    /*
    calculates the distance of an input node to the camera on each of the 3 axis, returns the value in centimeters
    */
    func calculateNodeDistanceVectorToCamera (incident: Incident?) -> SCNVector3? {
        guard let currentFrame = self.sceneView.session.currentFrame, let incident = incident else {
            return nil
        }
        let worldCoordinate = sceneView.scene.rootNode.convertPosition(SCNVector3(incident.coordinate.pointX,
                                                                                  incident.coordinate.pointY,
                                                                                  incident.coordinate.pointZ),
                                                                       to: nil)
        return SCNVector3(x: (currentFrame.camera.transform.columns.3.x - worldCoordinate.x) * 100,
                          y: (currentFrame.camera.transform.columns.3.y - worldCoordinate.y) * 100,
                          z: (currentFrame.camera.transform.columns.3.z - worldCoordinate.z) * 100)
    }
    
    /*
     Helper methods to calculate distances between incident and camera
    */
    func distanceTravelled(xDist: Float, yDist: Float, zDist: Float) -> Float {
        return sqrt((xDist * xDist) + (yDist * yDist) + (zDist * zDist))
    }
    
    func distanceTravelled(between v1: SCNVector3, and v2: SCNVector3) -> Float {
        
        let xDist = v1.x - v2.x
        let yDist = v1.y - v2.y
        let zDist = v1.z - v2.z
        
        return distanceTravelled(xDist: xDist, yDist: yDist, zDist: zDist)
    }
    
    func distanceCameraNode (incident: Incident?) -> Float? {
        
        guard let currentFrame = self.sceneView.session.currentFrame, let incident = incident else {
            return nil
        }
        return distanceTravelled(between: SCNVector3(x: currentFrame.camera.transform.columns.3.x,
                                                     y: currentFrame.camera.transform.columns.3.y,
                                                     z: currentFrame.camera.transform.columns.3.z),
                                 and: self.sceneView.scene.rootNode.convertPosition(SCNVector3(incident.coordinate.pointX,
                                                                                               incident.coordinate.pointY,
                                                                                               incident.coordinate.pointZ),
                                                                                    to: nil))
    }
    /*
     return the closest incident with status open
    */
    func closestOpenIncident () -> Incident? {
        
        let openIncidents = DataHandler.incidents.filter({ $0.status == .open })
        var openIncidentsDistances = [Float: Incident]()
        for incident in openIncidents {
            guard let distance = distanceCameraNode(incident: incident) else {
                return nil
            }
            openIncidentsDistances[distance] = incident
        }
        let closestIncident = openIncidentsDistances.min { a, b in a.key < b.key }
        guard let incident = closestIncident else {
            return nil
        }
        return incident.value
    }
    
    
    
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
                    guard let name = node.name else {
                        return
                    }
                    self.scene.rootNode.childNode(withName: name, recursively: false)?.removeFromParentNode()
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
                guard let name = node.name else {
                    return
                }
                self.scene.rootNode.childNode(withName: name, recursively: false)?.removeFromParentNode()
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1), execute: {
                    self.scene.rootNode.addChildNode(tmpNode)
                })
            }
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
