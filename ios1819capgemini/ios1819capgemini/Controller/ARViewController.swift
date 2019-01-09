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
import MultipeerConnectivity

//swiftlint:disable all
// Stores all the nodes added to the scene
var nodes = [SCNNode]()
// MARK: - ARViewController
class ARViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    // MARK: IBOutlets
    //outlets bitte nicht private
    @IBOutlet weak var arrowLabel: UILabel!
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var rightNavigation: UILabel!
    @IBOutlet weak var upNavigation: UILabel!
    @IBOutlet weak var leftNavigation: UILabel!
    @IBOutlet weak var downNavigation: UILabel!
    
    
    // MARK: Stored Instance Properties
    static var objectDetected = false
    var detectedObjectNode: SCNNode?
    let scene = SCNScene()
    let ssdPostProcessor = SSDPostProcessor(numAnchors: 1917, numClasses: 2)
    var screenHeight: Double?
    var screenWidth: Double?
    let numBoxes = 100
    var boundingBoxes: [BoundingBox] = []
    var model: VNCoreMLModel?
    var multipeerSession: MultipeerSession!
    var automaticallyDetectedIncidents = [CGPoint]()
    var descriptionNode = SKLabelNode(text: "")
    var anchorLabels = [UUID: String]()
    var objectAnchor: ARObjectAnchor?
    var mapProvider: MCPeerID?
    static var incidentEdited = false
    private var infoPlanePlaced = false
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
    
    // MARK: IBActions
    @IBAction private func shareButtonPressed(_ sender: Any) {
        sceneView.session.getCurrentWorldMap { worldMap, error in
            guard let map = worldMap
                else { print("Error: \(error!.localizedDescription)"); return }
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                else { fatalError("can't encode map") }
            self.multipeerSession.sendToAllPeers(data)
//            print("world map sent")
        }
        do {
            let incidentsData = try JSONEncoder().encode(DataHandler.incidents)
            self.multipeerSession.sendToAllPeers(incidentsData)
//            print("datahandler.incidents sent")
            for incident in DataHandler.incidents {
                print("incident \(incident.identifier) = \(incident.getCoordinateToVector())")
            }
        } catch {
            print("DataHandler.incidents could not have been encoded")
        }
    }
    
    @IBAction private func resetButtonPressed(_ sender: Any) {
        DataHandler.incidents = []
        DataHandler.saveToJSON()
        self.scene.rootNode.childNodes.forEach { node in
            guard let name = node.name else {
                return
            }
            self.scene.rootNode.childNode(withName: name, recursively: false)?.removeFromParentNode()
        }
        nodes = []
        automaticallyDetectedIncidents = []
        self.scene.rootNode.childNode(withName: "info-plane", recursively: true)?.removeFromParentNode()
        let configuration = ARWorldTrackingConfiguration()
        if let detectionObjects = ARReferenceObject.referenceObjects(inGroupNamed: "TestObjects", bundle: Bundle.main) {
            configuration.detectionObjects = detectionObjects
            sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
            let notification = UINotificationFeedbackGenerator()
            
            DispatchQueue.main.async {
                notification.notificationOccurred(.success)
            }

        }
        do {
            let data = try JSONEncoder().encode(DataHandler.incidents)
            self.multipeerSession.sendToAllPeers(data)
        } catch _ {
            let notification = UINotificationFeedbackGenerator()
            
            DispatchQueue.main.async {
                notification.notificationOccurred(.error)
            }
            print("encoding DataHandler.incidents failed")
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
        sceneView.debugOptions = [.showFeaturePoints]
        model = try? VNCoreMLModel(for: stickerTest().model)
        setupBoxes()
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapped))
        sceneView.addGestureRecognizer(gestureRecognizer)
        configureLighting()
        multipeerSession = MultipeerSession(receivedDataHandler: receivedData)
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

    // MARK: AR Kit methods
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        // Do not enqueue other buffers for processing while another Vision task is still running.
        // The camera stream has only a finite amount of buffers available; holding too many buffers for analysis would starve the camera.
        guard currentBuffer == nil, case .normal = frame.camera.trackingState else {
            return
        }

//      uncomment for ar navigation compass
//        if let incident = closestOpenIncident() {
//            let angle = angleIncidentPOV(incident: incident)
//            if let angle = angle {
//                setArrow(angle: angle, incident: incident, for: frame.camera.trackingState)
//            }
//        }
        
//      uncomment for ar navigation arrow
//      setNavigationArrows(for: frame.camera.trackingState)
        updateNodes()
        updateStatus(for: frame, trackingState: frame.camera.trackingState)
        updateIncidents()
        updateInfoPlane()
        // Retain the image buffer for Vision processing.
        self.currentBuffer = frame.capturedImage
        classifyCurrentImage()
    }
    
    //method is automatically executed. scans the AR View for the object which should be detected
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
        
        if let objectAnchor = anchor as? ARObjectAnchor {
            let notification = UINotificationFeedbackGenerator()
            
            DispatchQueue.main.async {
                notification.notificationOccurred(.success)
            }
            self.objectAnchor = objectAnchor
            self.detectedObjectNode = node
            ARViewController.objectDetected = true
//            for incident in DataHandler.incidents {
//                add3DPin(vectorCoordinate: incident.getCoordinateToVector(), identifier: "\(incident.identifier)")
//            }
            addInfoPlane(carPart: objectAnchor.referenceObject.name ?? "Unknown Car Part")
        }
        return node
    }
    
    func updateIncidents() {
        if !ARViewController.objectDetected {
            return
        }
        for incident in DataHandler.incidents {
            if incidentHasNotBeenPlaced(incident: incident) {
                let coordinateRelativeObject = detectedObjectNode!.convertPosition(incident.getCoordinateToVector(), to: nil)
                add3DPin(vectorCoordinate: coordinateRelativeObject, identifier: "\(incident.identifier)")
            }

        }
    }
    
    func incidentHasNotBeenPlaced (incident: Incident) -> Bool {
        for node in nodes {
            if String(incident.identifier) == node.name {
                return false
            }
        }
        return true
    }

    //adds a 3D pin to the AR View
    //nicht private
    func add3DPin (vectorCoordinate: SCNVector3, identifier: String) {
        let sphere = SCNSphere(radius: 0.015)
        let materialSphere = SCNMaterial()
        materialSphere.diffuse.contents = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.9)
        sphere.materials = [materialSphere]
        let sphereNode = SCNNode(geometry: sphere)
        sphereNode.name = identifier
        sphereNode.position = vectorCoordinate
        self.scene.rootNode.addChildNode(sphereNode)
        nodes.append(sphereNode)
        updateInfoPlane()
    }
    
    //adds the info plane which displays the detected object and the number of incidents
    //nicht private
    func addInfoPlane (carPart: String) {
        guard let objectAnchor = self.objectAnchor else {
            return
        }
        guard !infoPlanePlaced else {
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
        planeNode.name = "info-plane"
        let labelNode = SKLabelNode(text: carPart)
        labelNode.fontSize = 40
        labelNode.color = UIColor.black
        labelNode.fontName = "Helvetica-Bold"
        labelNode.position = CGPoint(x: 120, y: 200)
        
        descriptionNode = SKLabelNode(text: "Incidents: \(DataHandler.incidents.count)")
        descriptionNode.fontSize = 30
        descriptionNode.fontColor = UIColor.green
        descriptionNode.fontName = "Helvetica-Bold"
        descriptionNode.position = CGPoint(x: 120, y: 50)
        spriteKitScene.addChild(descriptionNode)
        spriteKitScene.addChild(labelNode)
        planeNode.constraints = [SCNBillboardConstraint()]
        scene.rootNode.addChildNode(planeNode)
        infoPlanePlaced = true
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
                            //add aranchor for multiuser
                            let anchor = ARAnchor(name: "pin \(incident.identifier)", transform: hitResult.worldTransform)
                            
                            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: anchor, requiringSecureCoding: true)
                                else { fatalError("can't encode anchor") }
                            self.multipeerSession.sendToAllPeers(data)
                            
                            sceneView.session.add(anchor: anchor)
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
                        do {
                            let data = try JSONEncoder().encode(incident)
                            self.multipeerSession.sendToAllPeers(data)
                            statusViewController.showMessage("incident has been sent", autoHide: true)
                        } catch _ {
                            print("Encoding DataHandler.incidents failed")
                            let notification = UINotificationFeedbackGenerator()
                            
                            DispatchQueue.main.async {
                                notification.notificationOccurred(.error)
                            }
                        }
                        }
                    }
                    return
                }
                self.performSegue(withIdentifier: "ShowDetailSegue", sender: tappedNode)
            }
        }
    }
    
    //MARK: ML Methods
    
    /// - Tag: ClassificationRequest
    lazy var classificationRequest: VNCoreMLRequest = {
        
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
