//
//  ViewController.swift
//  ios1819capgemini
//
//  Created by RMMM on 06.11.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
// swiftlint:disable type_body_length

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
class ARViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    // MARK: Stored Instance Properties
    static var sendIncidentButtonPressed = false
    static var resetButtonPressed = false
    static var navigatingIncident: Incident?
    static var connectedToPeer = false
    static var incidentEdited = false
    static var objectDetected = false
    static var multiUserEnabled = UserDefaults.standard.bool(forKey: "multi_user")
    var detectedObjectNode: SCNNode?
    var detectionObjects = Set <ARReferenceObject>()
    var selectedCarPart: CarPart?
    let scene = SCNScene()
    let ssdPostProcessor = SSDPostProcessor(numAnchors: 1917, numClasses: 4)
    var screenHeight: Double?
    var screenWidth: Double?
    let numBoxes = 100
    var boundingBoxes: [BoundingBox] = []
    var model: VNCoreMLModel?
    var mapProvider: MCPeerID?
    // swiftlint:disable implicitly_unwrapped_optional
    var multipeerSession: MultipeerSession!
    // swiftlint:enable implicitly_unwrapped_optional
    var isDetecting = true
    
    var automaticallyDetectedIncidents = [CGPoint]()
    private var descriptionNode = SKLabelNode(text: "")
    private var anchorLabels = [UUID: String]()
    private var objectAnchor: ARObjectAnchor?
    private var node: SCNNode?
    // swiftlint:disable force_unwrapping implicit_return
    lazy var statusViewController: StatusViewController = {
        return children.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
    // swiftlint:enable force_unwrapping implicit_return
    
    // The pixel buffer being held for analysis; used to serialize Vision requests.
    private var currentBuffer: CVPixelBuffer?
    // Queue for dispatching vision classification requests
    private let visionQueue = DispatchQueue(label: "serialVisionQueue")
    
    var imageHighlightAction: SCNAction {
        return .sequence([
            .wait(duration: 0.25),
            .fadeOpacity(to: 0.9, duration: 0.25),
            .fadeOpacity(to: 0.15, duration: 0.25),
            .fadeOpacity(to: 1, duration: 0.25)])
    }
    var nodeBlinking: SCNAction {
        return .sequence([
            .fadeOpacity(to:0.5, duration:0.1),
            .fadeOpacity(to:1.0, duration:0.1)])
    }
    // MARK: IBOutlets
    //sceneview bitte nicht private
    // swiftlint:disable private_outlet
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var connectionLabel: UILabel!
    @IBOutlet weak var arrowUp: UIImageView!
    @IBOutlet weak var arrowRight: UIImageView!
    @IBOutlet weak var arrowLeft: UIImageView!
    @IBOutlet weak var arrowDown: UIImageView!
    // swiftlint:enable private_outlet
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
        model = try? VNCoreMLModel(for: piktogramModel().model)
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
    
    /*
     recognizes if the screen has been tapped, creates a new pin and a matching incident if the tapped location is not a pin, otherwise
     opens the detail view for the tapped pin.
     If a new pin is created a screenshot of the location is taken before/after placing the pin.
     */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        if !creatingNodePossible {
            return
        }
        guard let touchesFirst = touches.first else {
            print("touches first error")
            return
        }
        let location = touchesFirst.location(in: sceneView)
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
                        self.selectedCarPart?.incidents.append(incident)
                        DataHandler.incidents.append(incident)
                        
                        self.sendIncident(incident: incident)
                    }
                }
            }
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
            DispatchQueue.global().async {
                do {
                    try object.export(
                        to: FileManager.default.urls(
                            for: .documentDirectory,
                            in: .userDomainMask)[0].appendingPathComponent((object.name ?? "dashboard") + ".arobject"),
                        previewImage: nil)
                    DataHandler.setCarParts()
                } catch {
                    fatalError("failed to save default scans to .userDomain ")
                }
            }
        }
        config.detectionObjects = detectionObjects
        sceneView.session.run(config)
    }
    
    // MARK: AR Kit methods
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        guard currentBuffer == nil, case .normal = frame.camera.trackingState else {
            return
        }
        
        updateSession(for: frame.camera.trackingState, incident: ARViewController.navigatingIncident)
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
            
//            if DataHandler.objectsToIncidents[name] != nil {
//                DataHandler.incidents = DataHandler.getIncidentsOfObject(identifier: name)
//            } else {
//                DataHandler.incidents = []
//            }
            
            selectedCarPart = DataHandler.carParts.first(where: { $0.name.hasPrefix(name) })
            guard let selectedCarPart = selectedCarPart else {
                print("no carPart with name \(name)")
                return node
            }
            DataHandler.incidents = selectedCarPart.incidents
            
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
    
    
    
    /// - Tag: ClassificationRequest
    private lazy var classificationRequest: VNCoreMLRequest = {
        // swiftlint:disable force_unwrapping
        let request = VNCoreMLRequest(model: model!, completionHandler: { [weak self] request, error in
            guard let predictions = self?.processClassifications(for: request, error: error) else {
                return
            }
            DispatchQueue.main.async {
                self?.drawBoxes(predictions: predictions)
            }
        })
        // swiftlint:enable force_unwrapping
        request.imageCropAndScaleOption = .centerCrop
        request.usesCPUOnly = true
        
        return request
    }()
    
    // Run the Vision+ML classifier on the current image buffer.
    /// - Tag: ClassifyCurrentImage
    private func classifyCurrentImage() {
        
        let orientation = CGImagePropertyOrientation(UIDevice.current.orientation)
        
        guard let cvPixelBuffer = currentBuffer else {
            return
        }
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: cvPixelBuffer, orientation: orientation)
        visionQueue.async {
            do {
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
    func add3DPin (vectorCoordinate: SCNVector3, identifier: String) {
        
        let sphere = SCNSphere(radius: 0.015)
        let materialSphere = SCNMaterial()
        // swiftlint:disable object_literal
        materialSphere.diffuse.contents = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.9)
        // swiftlint:enable object_literal
        sphere.materials = [materialSphere]
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.name = identifier
        sphereNode.position = vectorCoordinate
        self.scene.rootNode.addChildNode(sphereNode)
        nodes.append(sphereNode)
    }
    
    func setDescriptionLabel() {
        
        let openIncidents = (DataHandler.incidents.filter { $0.status == .open }).count
        let incidentsInProgress = (DataHandler.incidents.filter { $0.status == .progress }).count
        let resolvedIncidents = (DataHandler.incidents.filter { $0.status == .resolved }).count
        descriptionNode.text = """
        Number of incidents: \(DataHandler.incidents.count)
        Open: \(openIncidents)
        In progress: \(incidentsInProgress)
        Resolved: \(resolvedIncidents)
        """
    }
    
    //adds the info plane which displays the detected object and the number of incidents
    func addInfoPlane (carPart: String) {
        
        guard let objectAnchor = self.objectAnchor,
            let name = objectAnchor.referenceObject.name else {
                print("no object anchor found or its reference object has no name")
                return
        }
        let width = 0.1
        let height = 0.07
        let plane = SCNPlane(width: CGFloat(width),
                             height: CGFloat(height))
        plane.cornerRadius = plane.width / 45
        let spriteKitScene = SKScene(size: CGSize(width: 400, height: 280))
        // swiftlint:disable object_literal
        spriteKitScene.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.9)
        // swiftlint:enable object_literal
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
        labelNode.fontSize = 35
        labelNode.fontName = "HelveticaNeue-Medium"
        labelNode.position = CGPoint(x: 200, y: 200)
        labelNode.numberOfLines = 2
        labelNode.preferredMaxLayoutWidth = CGFloat(380)
        labelNode.lineBreakMode = .byWordWrapping
        
        setDescriptionLabel()
        descriptionNode.fontSize = 27
        descriptionNode.fontName = "HelveticaNeue-Light"
        descriptionNode.position = CGPoint(x: 180, y: 50)
        descriptionNode.numberOfLines = 4
        descriptionNode.lineBreakMode = NSLineBreakMode.byWordWrapping
        setDescriptionLabel()
        
        spriteKitScene.addChild(descriptionNode)
        spriteKitScene.addChild(labelNode)
        planeNode.constraints = [SCNBillboardConstraint()]
        
        scene.rootNode.addChildNode(planeNode)
    }
    
    @objc func tapped(recognizer: UIGestureRecognizer) {
        if recognizer.state != .began {
            progressRing.resetProgress()
            progressRing.isHidden = true
        }
    }
    
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
