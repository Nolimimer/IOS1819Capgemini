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
import UICircularProgressRing
import MultipeerConnectivity

// Stores all the nodes added to the scene
var nodes = [SCNNode]()
var creatingNodePossible = true

// MARK: - ARViewController
// swiftlint:disable all
class ARViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    // MARK: Stored Instance Properties
    static var sendIncidentButtonPressed = false
    static var resetButtonPressed = false
    static var navigatingIncident : Incident?
    static var connectedToPeer = false
    static var incidentEdited = false
    static var objectDetected = false
    var detectedObjectNode: SCNNode?
    var detectionObjects = Set <ARReferenceObject>()
    let scene = SCNScene()
    let ssdPostProcessor = SSDPostProcessor(numAnchors: 1917, numClasses: 2)
    var screenHeight: Double?
    var screenWidth: Double?
    let numBoxes = 100
    var boundingBoxes: [BoundingBox] = []
    var model: VNCoreMLModel?
    var mapProvider: MCPeerID?
    var multipeerSession: MultipeerSession!
    var isDetecting = true

    var automaticallyDetectedIncidents = [CGPoint]()
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
    private let visionQueue = DispatchQueue(label: "serialVisionQueue")
    
    var imageHighlightAction: SCNAction {
        return .sequence([
            .wait(duration: 0.25),
            .fadeOpacity(to: 0.9, duration: 0.25),
            .fadeOpacity(to: 0.15, duration: 0.25),
            .fadeOpacity(to: 1, duration: 0.25),
            ])
    }
    var nodeBlinking: SCNAction {
        return .sequence([
            .fadeOpacity(to:0.5, duration:0.1),
            .fadeOpacity(to:1.0, duration:0.1)
            ])
    }
    // MARK: IBOutlets
    //sceneview bitte nicht private
    @IBOutlet var sceneView: ARSCNView!
 
    @IBOutlet weak var arrowUp: UIImageView!
    @IBOutlet weak var arrowRight: UIImageView!
    @IBOutlet weak var arrowLeft: UIImageView!
    @IBOutlet weak var arrowDown: UIImageView!
    
    @IBOutlet private weak var progressRing: UICircularProgressRing!

    // MARK: Overridden/Lifecycle Methods
    override func viewDidLoad() {
        creatingNodePossible = true
        super.viewDidLoad()
        sceneView.delegate = self
        sceneView.showsStatistics = false
        sceneView.scene = scene
        
        sceneView.debugOptions = [.showFeaturePoints]
        sceneView.session.delegate = self
        screenWidth = Double(view.frame.width)
        screenHeight = Double(view.frame.height)
        sceneView.debugOptions = [.showFeaturePoints]
        model = try? VNCoreMLModel(for: stickerTest().model)
        setupBoxes()
        configureLighting()
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        sceneView.addGestureRecognizer(gestureRecognizer)
        multipeerSession = MultipeerSession(receivedDataHandler: receivedData)
    }
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        screenWidth = Double(size.width)
        screenHeight = Double(size.height)
        if UIDevice.current.orientation.isLandscape {
        } else {
        }
    }
  
    func reset() {
        if let name = objectAnchor?.referenceObject.name {
        DataHandler.objectsToIncidents[name] = DataHandler.incidents
        }
        DataHandler.saveToJSON()
        self.scene.rootNode.childNodes.forEach { node in
            guard let name = node.name else {
                return
            }
            self.scene.rootNode.childNode(withName: name, recursively: false)?.removeFromParentNode()
        }
        DataHandler.incidents = []
        nodes = []
        detectedObjectNode = nil
        automaticallyDetectedIncidents = []
        self.scene.rootNode.childNode(withName: "info-plane", recursively: true)?.removeFromParentNode()
        let config = ARWorldTrackingConfiguration()
        loadCustomScans()
        guard let testObjects = ARReferenceObject.referenceObjects(inGroupNamed: "TestObjects", bundle: Bundle.main) else {
            return
        }
        for object in testObjects {
            detectionObjects.insert(object)
        }
        config.detectionObjects = detectionObjects
        sceneView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
        do {
            let data = try JSONEncoder().encode(DataHandler.incidents)
            self.multipeerSession.sendToAllPeers(data)
        } catch _ {
            let notification = UINotificationFeedbackGenerator()
        
            DispatchQueue.main.async {
                notification.notificationOccurred(.error)
            }
        }
    }
    
    func checkReset() {
        if !ARViewController.resetButtonPressed {
            return
        } else {
            reset()
            ARViewController.resetButtonPressed = false
        }
    }
    
    func checkSendIncidents() {
        if !ARViewController.sendIncidentButtonPressed {
            return
        } else {
            sendIncidents()
            ARViewController.resetButtonPressed = false
        }
    }
    
    /*
     recognizes if the screen has been tapped, creates a new pin and a matching incident if the tapped location is not a pin, otherwise
     opens the detail view for the tapped pin.
     If a new pin is created a screenshot of the location is taken before/after placing the pin.
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !creatingNodePossible {
            return
        }
        let location = touches.first!.location(in: sceneView)
        let hitResultsFeaturePoints: [ARHitTestResult] = sceneView.hitTest(location, types: .featurePoint)
        if let touch = touches.first {
            if let hitResult = hitResultsFeaturePoints.first {
                if let node = getNodeInRadius(hitResult: hitResult, radius: 0.015) {
                    self.performSegue(withIdentifier: "ShowDetailSegue", sender: node)
                    return
                }
                let position = touch.location(in: view)
                progressRing.frame.origin.x = position.x - 110
                progressRing.frame.origin.y = position.y - 60
                progressRing.isHidden = false
                progressRing.maxValue = 100
                progressRing.startProgress(to: 100, duration: 1.0) {
                self.progressRing.isHidden = true
                self.progressRing.resetProgress()
                    if self.detectedObjectNode != nil {
                        let coordinateRelativeToObject = self.sceneView.scene.rootNode.convertPosition(
                            SCNVector3(hitResult.worldTransform.columns.3.x,
                                        hitResult.worldTransform.columns.3.y,
                                        hitResult.worldTransform.columns.3.z),
                            to: self.detectedObjectNode)
                        let incident = Incident (type: .unknown,
                                                 description: "New Incident",
                                                 coordinate: Coordinate(vector: coordinateRelativeToObject))
                        self.filterAllPins()
                        let imageWithoutPin = self.sceneView.snapshot()
                        self.saveImage(image: imageWithoutPin, incident: incident)
                        self.add3DPin(vectorCoordinate: SCNVector3(hitResult.worldTransform.columns.3.x,
                                                                    hitResult.worldTransform.columns.3.y,
                                                                    hitResult.worldTransform.columns.3.z),
                                      identifier: "\(incident.identifier)" )
                        self.filter3DPins(identifier: "\(incident.identifier)")
                        let imageWithPin = self.sceneView.snapshot()
                        self.saveImage(image: imageWithPin, incident: incident)
                        DataHandler.incidents.append(incident)
                        self.sendIncident(incident: incident)
                    }
                }
            }
        }
    }
    
    func loadCustomScans() {
        let fileManager = FileManager.default
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            for file in fileURLs {
                if file.lastPathComponent.hasSuffix(".arobject") {
                    let arRefereceObject = try ARReferenceObject(archiveURL: file)
                    detectionObjects.insert(arRefereceObject)
                }
            }
        } catch {
            print("Error loading custom scans")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let config = ARWorldTrackingConfiguration()
        
        loadCustomScans()
        guard let testObjects = ARReferenceObject.referenceObjects(inGroupNamed: "TestObjects", bundle: Bundle.main) else {
            return
        }
        for object in testObjects {
            detectionObjects.insert(object)
        }
        config.detectionObjects = detectionObjects
        sceneView.session.run(config)
    }
    
    // MARK: AR Kit methods
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Do not enqueue other buffers for processing while another Vision task is still running.
        // The camera stream has only a finite amount of buffers available; holding too many buffers for analysis would starve the camera.
        guard currentBuffer == nil, case .normal = frame.camera.trackingState else {
            return
        }
        if !multipeerSession.connectedPeers.isEmpty {
            ARViewController.connectedToPeer = true
        }
        
        // Check settings
        if UserDefaults.standard.bool(forKey: "enable_boundingboxes") {
            sceneView.debugOptions = [.showFeaturePoints, .showBoundingBoxes]
        } else if UserDefaults.standard.bool(forKey: "enable_featurepoints") {
            sceneView.debugOptions = [.showFeaturePoints]
        } else {
            sceneView.debugOptions = []
        }
        if UserDefaults.standard.bool(forKey: "enable_detection") && detectedObjectNode != nil {
            isDetecting = true
            setupBoxes()
        } else {
            hideBoxes()
            isDetecting = false
        }
        checkReset()
        checkSendIncidents()
        updateIncidents()
        refreshNodes()
        updatePinColour()
        setDescriptionLabel()
        setNavigationArrows(for: frame.camera.trackingState, incident: ARViewController.navigatingIncident)
        // Retain the image buffer for Vision processing.
        self.currentBuffer = frame.capturedImage
        classifyCurrentImage()
    }
    

    //method is automatically executed. scans the AR View for the object which should be detected
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        
        let node = SCNNode()
        
        if detectedObjectNode != nil {
            return node
        }
        if let objectAnchor = anchor as? ARObjectAnchor {
            guard let name = objectAnchor.referenceObject.name else { fatalError("reference object has no name") }
            
            if DataHandler.objectsToIncidents[name] != nil {
                DataHandler.incidents = DataHandler.getIncidentsOfObject(identifier: name)
            } else {
                DataHandler.incidents = []
            }
            ModelViewController.objectName = name
            let notification = UINotificationFeedbackGenerator()
            
            DispatchQueue.main.async {
                notification.notificationOccurred(.success)
            }
            self.node = node
            self.objectAnchor = objectAnchor
            self.detectedObjectNode = node
            addInfoPlane(carPart: objectAnchor.referenceObject.name ?? "Unknown Car Part")
            ARViewController.objectDetected = true
        }
        return node
    }
    
    func updateIncidents() {
        
        if !ARViewController.objectDetected {
            return
        }
        incidentEditted()
        for incident in DataHandler.incidents {
            if incidentHasNotBeenPlaced(incident: incident) {
                let coordinateRelativeObject = detectedObjectNode!.convertPosition(incident.getCoordinateToVector(), to: nil)
                add3DPin(vectorCoordinate: coordinateRelativeObject, identifier: "\(incident.identifier)")
            }
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
    
    private func setDescriptionLabel() {
        
        let openIncidents = (DataHandler.incidents.filter { $0.status == .open}).count
        let incidentsInProgress = (DataHandler.incidents.filter { $0.status == .progress}).count
        let resolvedIncidents = (DataHandler.incidents.filter { $0.status == .resolved}).count
        descriptionNode.text = """
        Number of incidents: \(DataHandler.incidents.count)\r\n
        Open: \(openIncidents)\r\n
        In progress: \(incidentsInProgress)\r\n
        Resolved: \(resolvedIncidents)
        """
    }
    
    //adds the info plane which displays the detected object and the number of incidents
    private func addInfoPlane (carPart: String) {
        
        guard let objectAnchor = self.objectAnchor,
        let name = objectAnchor.referenceObject.name else {
            print("no object anchor found or its reference object has no name")
            return
        }
        let width = objectAnchor.referenceObject.extent.x * 0.8
        let height = objectAnchor.referenceObject.extent.y * 0.5
        let plane = SCNPlane(width: CGFloat(width),
                             height: CGFloat(height))
        plane.cornerRadius = plane.width / 45
        let spriteKitScene = SKScene(size: CGSize(width: 500, height: 500))
        spriteKitScene.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.9)
        plane.firstMaterial?.diffuse.contents = spriteKitScene
        plane.firstMaterial?.isDoubleSided = true
        plane.firstMaterial?.diffuse.contentsTransform = SCNMatrix4Translate(SCNMatrix4MakeScale(1, -1, 1), 0, 1, 0)
        let planeNode = SCNNode(geometry: plane)
        let absoluteObjectPosition = objectAnchor.transform.columns.3
        let planePosition = SCNVector3(absoluteObjectPosition.x,
                                       absoluteObjectPosition.y + 1.5 * objectAnchor.referenceObject.extent.y,
                                       absoluteObjectPosition.z)
        planeNode.position = planePosition
        planeNode.name = "info-plane"
        let labelNode = SKLabelNode(text: name)
        labelNode.fontSize = 40
        labelNode.fontName = "HelveticaNeue-Medium"
        labelNode.position = CGPoint(x: 250, y: 400)
        labelNode.numberOfLines = 2
        labelNode.preferredMaxLayoutWidth = CGFloat(450)
        labelNode.lineBreakMode = .byWordWrapping
        
        descriptionNode.fontSize = 30
        descriptionNode.fontName = "HelveticaNeue-Light"
        descriptionNode.position = CGPoint(x: 200, y: 100)
        descriptionNode.numberOfLines = 4
        descriptionNode.lineBreakMode = NSLineBreakMode.byWordWrapping
        setDescriptionLabel()

        spriteKitScene.addChild(descriptionNode)
        spriteKitScene.addChild(labelNode)
        planeNode.constraints = [SCNBillboardConstraint()]
        
        scene.rootNode.addChildNode(planeNode)
    }

    @objc func tapped(recognizer: UIGestureRecognizer) {
        if recognizer.state != .began  {
            progressRing.resetProgress()
            progressRing.isHidden = true
        }
    }
    
    private func updateInfoPlane() {
        descriptionNode.text = "Incidents : \(DataHandler.incidents.count)"
        let openIncidentsCount = DataHandler.incidents.filter { $0.status == .open }
        if openIncidentsCount.isEmpty {
            descriptionNode.fontColor = UIColor.green
        } else {
            descriptionNode.fontColor = UIColor.red
        }
    }
    
    func refreshNodes() {
        for node in nodes {
            guard let name = node.name else {
                return
            }
            if DataHandler.incidents.isEmpty {
                do {
                    let data = try JSONEncoder().encode(DataHandler.incidents)
                    self.multipeerSession.sendToAllPeers(data)
                } catch {
                    print("sending incidents array failed (refreshNodes DataHandler.incidents.isEmpty)")
                }
            }
            if DataHandler.incident(withId: name) == nil {
                self.scene.rootNode.childNode(withName: name, recursively: false)?.removeFromParentNode()
                deleteNode(identifier: name)
                do {
                    let data = try JSONEncoder().encode(DataHandler.incidents)
                    self.multipeerSession.sendToAllPeers(data)
                } catch {
                    print("sending incidents array failed (refreshNodes DataHandler.incident(withId: name) == nil")
                }
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
