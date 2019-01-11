//
//  DetailViewController.swift
//  ios1819capgemini
//
//  Created by Thomas Böhm on 19.11.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

// MARK: Imports
import UIKit
import AVKit
import INSPhotoGallery
import MobileCoreServices
import SceneKit

//swiftlint:disable all
// MARK: - DetailViewController
class DetailViewController: UIViewController, UINavigationControllerDelegate, UIDocumentInteractionControllerDelegate {
    
    private var modus = Modus.view
    var recordButton: UIButton!
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer?
    
    private var types: [IncidentType] = []
    private var type = IncidentType.unknown
    
    private var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
        return dateFormatter
    }
    
    // Variables / Mock Variable
    var incident: Incident?
    var attachments: [Attachment] = []
    //swiftlint:disable implicitly_unwrapped_optional
    var imagePicker: UIImagePickerController!
    var documentInteractionController: UIDocumentInteractionController!
    //swiftlint:enable implicitly_unwrapped_optional

    // MARK: IBOutlets
    @IBOutlet private weak var navigationItemIncidentTitle: UINavigationItem!
    @IBOutlet private weak var generatedDateLabel: UILabel!
    @IBOutlet private weak var lastModifiedDateLabel: UILabel!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var segmentControll: UISegmentedControl!
    @IBOutlet private weak var backButton: UIBarButtonItem!
    @IBOutlet private weak var textField: UITextView!
    @IBOutlet private weak var editButton: UIBarButtonItem!
    @IBOutlet private weak var incidentTypeButton: UIButton!
    @IBOutlet private weak var popUpIncidentTypeView: UIView!
    @IBOutlet private weak var whiteViewFromPopUp: UIView!
    @IBOutlet private weak var incidentTypePicker: UIPickerView!
    
    // MARK: IBActions
    @IBAction private func incidentTypeButtonPressed(_ sender: Any) {
        whiteViewFromPopUp.layer.cornerRadius = 10
        popUpIncidentTypeView.isHidden = false
        guard let tmpIndexOfType = types.firstIndex(of: type) else {
            print("Error")
            return
        }
        incidentTypePicker.selectRow(tmpIndexOfType, inComponent: 0, animated: false)
    }
    
    @IBAction private func selectIncidentType(_ sender: Any) {
        incidentTypeButton.setTitle(type.rawValue, for: .normal)
        popUpIncidentTypeView.isHidden = true
    }
    
    @IBAction private func backButtonPressed(_ sender: Any) {
         creatingNodePossible = true
         self.dismiss(animated: true, completion: nil)
    }

    @IBAction func showAllAttachments(_ sender: Any) {
        //performSegue(withIdentifier: "attachmentSegue", sender: self)
    }
    
    @IBAction private func editButtonPressed(_ sender: Any) {
        switch modus {
        case .view:
            editButton.title = "Save"
            incidentTypeButton.isEnabled = true
            textField.isEditable = true
            segmentControll.isEnabled = true
            textField.layer.borderWidth = 1.0
            textField.layer.borderColor = UIColor.white.cgColor
            
            modus = .edit
        case .edit:
            // Saves changes
            var status: Status
            switch segmentControll.selectedSegmentIndex {
            case 0:
                status = .open
            case 1:
                status = .progress
            default:
                status = .resolved
            }
            guard let tmpIncident = incident else {
                print("Error")
                return
            }
            tmpIncident.edit(status: status, description: textField.text, modifiedDate: Date())
            tmpIncident.editIncidentType(type: type)
            editButton.title = "Edit"
            textField.isEditable = false
            segmentControll.isEnabled = false
            incidentTypeButton.isEnabled = false
            textField.layer.borderWidth = 0.0
            lastModifiedDateLabel.text = dateFormatter.string(from: tmpIncident.modifiedDate)
            modus = .view
        }
    }
   
    // MARK: Overridden/Lifecycle Methods
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        if let firstTouch = touches.first {
            let hitView = self.view.hitTest(firstTouch.location(in: self.view), with: event)
            
            let attachmentView = view.subviews.first {
                $0 is AttachmentView
            }
            if hitView != attachmentView {
                attachmentView?.removeFromSuperview()
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        if let firstTouch = touches.first {
            let hitView = self.view.hitTest(firstTouch.location(in: self.view), with: event)
            
            let attachmentView = view.subviews.first {
                $0 is AttachmentView
            }
            if hitView != attachmentView {
                attachmentView?.removeFromSuperview()
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        if let firstTouch = touches.first {
            let hitView = self.view.hitTest(firstTouch.location(in: self.view), with: event)
            
            let attachmentView = view.subviews.first {
                $0 is AttachmentView
            }
            if hitView != attachmentView {
                attachmentView?.removeFromSuperview()
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
        if let firstTouch = touches.first {
            let hitView = self.view.hitTest(firstTouch.location(in: self.view), with: event)
            
            let attachmentView = view.subviews.first {
                $0 is AttachmentView
            }
            if hitView != attachmentView {
                attachmentView?.removeFromSuperview()
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        creatingNodePossible = false
        modalPresentationStyle = .overCurrentContext
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)

//        navigationItemIncidentTitle.title = "\(incident.type.rawValue) \(incident.identifier)"
        
        let controllIndex: Int
        guard let tmpIncident = incident else {
            print("Error")
            return
        }
        switch tmpIncident.status {
        case .open:
            controllIndex = 0
        case .progress:
            controllIndex = 1
        case .resolved:
            controllIndex = 2
        }
        segmentControll.selectedSegmentIndex = controllIndex
        
        let dateString = dateFormatter.string(from: tmpIncident.createDate)
        let lastModifiedDateString = dateFormatter.string(from: tmpIncident.modifiedDate)
        generatedDateLabel.text = dateString
        lastModifiedDateLabel.text = lastModifiedDateString

        textField.text = incident?.description
        attachments = []
        attachments.append(Photo(name: "plusButton", photoPath: "errorPath"))
        attachments.append(contentsOf: (incident!.attachments))
        collectionView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
        } catch {
            print("Failed to record audio!")
        }
        attachments = []
        attachments.append(Photo(name: "plusButton", photoPath: "errorPath"))
        attachments.append(contentsOf: (incident!.attachments))
        
//        let gesture = UITapGestureRecognizer(target: self, action:  #selector (self.handleTap(recognizer:)))
//        self.view.addGestureRecognizer(gesture)
        // add blurred subview
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = UIScreen.main.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.navigationController?.view.addSubview(blurView)
        self.navigationController?.view.sendSubviewToBack(blurView)
        IncidentType.allCases.forEach {
            types.append($0)
        }
        popUpIncidentTypeView.isHidden = true
        incidentTypePicker.dataSource = self
        incidentTypePicker.delegate = self
    }
    
    func hidePopup() {
        for child in view.subviews {
            if child is AttachmentView {
                child.removeFromSuperview()
            }
        }
    }
    
    
    func reloadCollectionView() {
        attachments = []
        attachments.append(Photo(name: "plusButton", photoPath: "errorPath"))
        attachments.append(contentsOf: (incident!.attachments))
        collectionView.reloadData()
    }
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    func documentInteractionControllerViewForPreview(_ controller: UIDocumentInteractionController) -> UIView? {
        return self.view
    }
    
    func documentInteractionControllerRectForPreview(_ controller: UIDocumentInteractionController) -> CGRect {
        return self.view.frame
    }

    
    func finishRecording(success: Bool) {
        
        audioRecorder?.stop()
        let duration = audioRecorder.currentTime
        audioRecorder = nil
        if success {
            let paths = NSSearchPathForDirectoriesInDomains(
                FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            let defaults = UserDefaults.standard
            let name = "cARgeminiAudioAsset\(defaults.integer(forKey: "AttachedAudioName") - 1).m4a"
            let audioFilename = getDocumentsDirectory().appendingPathComponent(name)
            incident!.addAttachment(attachment: Audio(name: name, filePath: "\(paths[0])/\(name)", duration: duration))
            recordButton.setTitle("Audio", for: .normal)
            hidePopup()
            attachments = []
            attachments.append(Photo(name: "plusButton", photoPath: "errorPath"))
            attachments.append(contentsOf: (incident!.attachments))
            collectionView.reloadData()
        } else {
            recordButton.setTitle("Tap to Record", for: .normal)
        }
    }

    @objc func handleTap(recognizer: UITapGestureRecognizer) {
        self.view.endEditing(true)
        let location = recognizer.location(in: view)

        let attachmentView = view.subviews.first {
            $0 is AttachmentView
        }
        
        if attachmentView?.frame.contains(location) ?? false {
            attachmentView?.removeFromSuperview()
        }
    }

    @objc func recordTapped() {
        if audioRecorder == nil {
            startRecording()
        } else {
            finishRecording(success: true)
        }
    }
    

    @objc private func takePhoto() {
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    @objc private func takeVideo() {
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
        imagePicker.sourceType = .camera
        imagePicker.mediaTypes = [kUTTypeMovie as String]
        present(imagePicker, animated: true, completion: nil)
    }
    
    @objc private func recordAudio() {
        
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let alertController = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            present(alertController, animated: true)
        } else {
            print("Saved picture")

            let index = 0
            hidePopup()
        }
    }
    
    
    @objc private func pickDocument() {
        let importMenu = UIDocumentMenuViewController(documentTypes: [String(kUTTypePDF)], in: .import)
        importMenu.delegate = self
        importMenu.modalPresentationStyle = .formSheet
        self.present(importMenu, animated: true, completion: nil)
    }
    
}

// MARK: Extension
extension DetailViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return attachments.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).row == 0 {
            guard let tmpX = collectionView.cellForItem(at: indexPath) else {
                print("Error")
                return
            }
            let attachmentView = AttachmentView(frame: CGRect(x: tmpX.center.x - 30,
                                                              y: collectionView.center.y - 200,
                                                              width: 150,
                                                              height: 200))
            attachmentView.photoButton.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
             attachmentView.videoButton.addTarget(self, action: #selector(takeVideo), for: .touchUpInside)
             attachmentView.audioButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
            attachmentView.documentButton.addTarget(self, action: #selector(pickDocument), for: .touchUpInside)
            recordButton = attachmentView.audioButton
            view.addSubview(attachmentView)
            return
        }
        let currentAttachment = attachments[(indexPath as NSIndexPath).row]
        if currentAttachment is Video {
            let item = attachments[(indexPath as NSIndexPath).item]
            let player = AVPlayer(url: URL(fileURLWithPath: item.filePath))
            let playerController = AVPlayerViewController()
            playerController.player = player
            present(playerController, animated: true) {
                player.play()
            }
            return
        }
        if currentAttachment is Photo {
            let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCell
            guard let photo = currentAttachment as? Photo else {
                return
            }
            let photoWrapper = PhotoWrapper(photo: photo)
            let galleryPreview = INSPhotosViewController(photos: [photoWrapper], initialPhoto: photoWrapper, referenceView: cell)
            
            galleryPreview.referenceViewForPhotoWhenDismissingHandler = { [weak self] photo in
                if let index = self?.attachments.index(where: { $0 === photo }) {
                    let indexPath = IndexPath(item: index, section: 0)
                    return  collectionView.cellForItem(at: indexPath) as? ExampleCollectionViewCell
                }
                return nil
            }
            present(galleryPreview, animated: true, completion: nil)
        }
        if currentAttachment is Audio {
            let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCell
            guard let audio = currentAttachment as? Audio else {
                return
            }
            playSound(audio: audio)
        }
        if currentAttachment is TextDocument {
            let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCell
            guard let textDocument = currentAttachment as? TextDocument else {
                return
            }
            self.documentInteractionController = UIDocumentInteractionController.init(url: URL(fileURLWithPath: textDocument.filePath))
            self.documentInteractionController.delegate = self
            self.documentInteractionController.presentPreview(animated: true)
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "attachmentCell", for: indexPath) as? CollectionViewCell
        cell?.populateWithAttachment(attachments[(indexPath as NSIndexPath).row])
        return cell ?? UICollectionViewCell()
    }
}

extension DetailViewController: UIImagePickerControllerDelegate {
    //swiftlint:disable colon
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey:Any]) {
        imagePicker.dismiss(animated: true, completion: nil)
        if let selectedImage = info[.originalImage] as? UIImage {
            if saveImage(image: selectedImage) {
                print("Saved image")
            }
        }
        if let selectedVideo: URL = (info[UIImagePickerController.InfoKey.mediaURL] as? URL) {
            // Save video to the main photo album
            let selectorToCall = #selector(AttachmentViewController.videoSaved(_:didFinishSavingWithError:context:))
            
            // 2
            UISaveVideoAtPathToSavedPhotosAlbum(selectedVideo.relativePath, self, selectorToCall, nil)

            // Save the video to the app directory
            let videoData = try? Data(contentsOf: selectedVideo)
            //let a = Data
            let paths = NSSearchPathForDirectoriesInDomains(
                FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            let documentsDirectory = URL(fileURLWithPath: paths[0])
            let defaults = UserDefaults.standard
            let name = "cARgeminiVideoAsset\(defaults.integer(forKey: "AttachedVideoName")).mov"
            
            let dataPath = documentsDirectory.appendingPathComponent(name)
            defaults.set(defaults.integer(forKey: "AttachedVideoName") + 1, forKey: "AttachedVideoName")
            do {
                try videoData?.write(to: dataPath, options: [])
                incident?.addAttachment(attachment: Video(name: name, videoPath: "\(paths[0])/\(name)", duration: 3.0))
            } catch {
                print(Error.self)
            }
        }
    }
    
    //swiftlint:disable implicitly_unwrapped_optional
    @objc func videoSaved(_ video: String, didFinishSavingWithError error: NSError!, context: UnsafeMutableRawPointer) {
        //swiftlint:enable implicitly_unwrapped_optional
        if let theError = error {
            print("error saving the video = \(theError)")
        } else {
            DispatchQueue.main.async(execute: { () -> Void in })
        }
        hidePopup()
    }
    
    func saveImage(image: UIImage) -> Bool {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        
        let paths = NSSearchPathForDirectoriesInDomains(
            FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentsDirectory = URL(fileURLWithPath: paths[0])
        
        guard let data = image.jpegData(compressionQuality: 0.5) else {
            return false
        }
        do {
            let defaults = UserDefaults.standard
            let name = "cARgeminiasset\(defaults.integer(forKey: "AttachedPhotoName")).jpg"
            let path = documentsDirectory.appendingPathComponent(name)
            try data.write(to: path, options: [])
            defaults.set(defaults.integer(forKey: "AttachedPhotoName") + 1, forKey: "AttachedPhotoName")
            incident?.addAttachment(attachment: Photo(name: name, photoPath: "\(paths[0])/\(name)"))
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
}

extension DetailViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return types.count
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        type = types[row]
        //        self.navigationController?.setNavigationBarHidden(false, animated: false)
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return types[row].rawValue
    }
    
}

// MARK: Constants
enum Modus {
    case view
    case edit
}
