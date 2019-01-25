//
//  DetailViewController.swift
//  ios1819capgemini
//
//  Created by Thomas Böhm on 19.11.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//
// swiftlint:disable file_length

// MARK: Imports
import UIKit
import AVKit
import INSPhotoGallery
import MobileCoreServices
import SceneKit


// MARK: - DetailViewController
class DetailViewController: UIViewController, UINavigationControllerDelegate, UIDocumentInteractionControllerDelegate {
    
    private var modus = Modus.view
    //swiftlint:disable implicitly_unwrapped_optional
    private var overlay: UIView! = nil
    var recordButton: UIButton!
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    //swiftlint:enable implicitly_unwrapped_optional
    var audioPlayer: AVAudioPlayer?
    
    private var types: [IncidentType] = []
    private var type = IncidentType.other
    
    private var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
        return dateFormatter
    }
    
    // Variables / Mock Variable
    var incident: Incident?
    var attachments: [AnyAttachment] = []
    // swiftlint:disable implicitly_unwrapped_optional
    var imagePicker: UIImagePickerController!
    var documentInteractionController: UIDocumentInteractionController!
    // swiftlint:enable implicitly_unwrapped_optional

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
            print("error index type button pressed")
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

    @IBAction private func showAllAttachments(_ sender: Any) {
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
                print("error edit button pressed")
                return
            }
            tmpIncident.edit(status: status, description: textField.text, modifiedDate: Date())
            tmpIncident.editIncidentType(type: type)
            editButton.title = "Edit"
            textField.isEditable = false
            segmentControll.isEnabled = false
            incidentTypeButton.isEnabled = false
            textField.layer.borderWidth = 0.0
            ARViewController.incidentEdited = true
            ARViewController.editedIncident = tmpIncident
            lastModifiedDateLabel.text = dateFormatter.string(from: tmpIncident.modifiedDate)
            modus = .view
            
        }
        setAttachmentsToEditMode()
    }
   
    // MARK: Overridden/Lifecycle Methods
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        creatingNodePossible = false
        modalPresentationStyle = .overCurrentContext
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)

        //navigationItemIncidentTitle.title = "\(incident.type.rawValue) \(incident.identifier)"
        
        let controllIndex: Int
        guard let tmpIncident = incident else {
            print("incident not initialized (view will appear DetailViewcontroller)")
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
        reloadCollectionView()
        guard let incident = incident else {
            print("incident not initialized in view will appear")
            return
        }
        type = incident.type
        incidentTypeButton.setTitle(type.rawValue, for: .normal)
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

        reloadCollectionView()

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
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let touch: UITouch? = touches.first
        
        if touch?.view == overlay {
            overlay.removeFromSuperview()
        }
    }
    
    func hidePopup() {
        for child in view.subviews where child is AttachmentView {
            child.removeFromSuperview()
        }
    }
    
    func reloadCollectionView() {
        attachments.removeAll()
       
        collectionView.reloadData()

        attachments.append(AnyAttachment(Photo(name: "plusButton", photoPath: "errorPath")))
        guard let incident = incident else {
            return
        }
        attachments.append(contentsOf: (incident.attachments))

        collectionView.reloadData()
    }
    
    func setAttachmentsToEditMode() {
        for item in collectionView.visibleCells {
            let cell = item as? CollectionViewCell
            cell?.changeDeleteButtonVisibility(isEdit: modus == Modus.edit ? true : false)
        }
    }
    
    func removeAttachment(withName name: String) {
        for attachment in attachments where attachment.attachment.name == name {
            incident?.removeAttachment(attachment: attachment.attachment)
        }
        reloadCollectionView()
        setAttachmentsToEditMode()
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
            guard let incident = incident else {
                print("error not recorded ")
                return
            }
            incident.addAttachment(attachment: Audio(name: name, filePath: "\(paths[0])/\(name)", duration: duration))
            recordButton.setTitle("Audio", for: .normal)
            hidePopup()
            reloadCollectionView()
            recordingSession = nil
            recordingSession = AVAudioSession.sharedInstance()
        } else {
            recordButton.setTitle("Tap to Record", for: .normal)
        }
    }
    
    @objc func recordTapped() {
        if audioRecorder == nil {
            do {
                try recordingSession.setCategory(.playAndRecord, mode: .default)
                try recordingSession.setActive(true)
            } catch {
                print("Cannot switch to play an record mode!")
                return
            }
            startRecording()
        } else {
            overlay.removeFromSuperview()
            finishRecording(success: true)
        }
    }
    

    @objc private func takePhoto() {
        overlay.removeFromSuperview()
        
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    @objc private func takeVideo() {
        overlay.removeFromSuperview()
        
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
        imagePicker.sourceType = .camera
        imagePicker.mediaTypes = [kUTTypeMovie as String]
        present(imagePicker, animated: true, completion: nil)
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let alertController = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            present(alertController, animated: true)
        } else {
            print("Saved picture")
            hidePopup()
        }
    }
    
    
    @objc private func pickDocument() {
        let importMenu = UIDocumentPickerViewController(documentTypes: [String(kUTTypePDF)], in: .import)
        importMenu.delegate = self
        importMenu.modalPresentationStyle = .formSheet
        self.present(importMenu, animated: true, completion: nil)
    }
    
    // Spotlights the attachment popup
    private func showOverlay() {
        overlay = UIView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height))
        overlay.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 0.5)
        view.addSubview(overlay)
    }
}

// MARK: Extension
extension DetailViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return attachments.count
    }
    
    //swiftlint:disable function_body_length cyclomatic_complexity
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).row == 0 {
            guard let tmpX = collectionView.cellForItem(at: indexPath) else {
                print("error in collection view ")
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
            
            showOverlay()
            overlay.addSubview(attachmentView)
            
            return
        }
        let currentAttachment = attachments[(indexPath as NSIndexPath).row].attachment
        if currentAttachment is Video {
            let item = attachments[(indexPath as NSIndexPath).item]
            let player = AVPlayer(url: URL(fileURLWithPath: item.attachment.filePath))
            let playerController = AVPlayerViewController()
            playerController.player = player
            present(playerController, animated: true) {
                player.play()
            }
            return
        }
        if currentAttachment is Photo {
            let cell = collectionView.cellForItem(at: indexPath) as? CollectionViewCell
            guard let photo = currentAttachment as? Photo,
                let incident = incident else {
                return
            }
            
            let photos: [PhotoWrapper] = incident.attachments.reduce([]) {
                var list = $0
                if $1.attachment is Photo {
                    // swiftlint:disable force_cast
                    list.append(PhotoWrapper(photo: $1.attachment as! Photo))
                }
                // swiftlint:enable force_cast
                return list
            }
            
            let initialPhoto = photos.first(where: { $0.photo.name == photo.name })
 
            let galleryPreview = INSPhotosViewController(photos: photos, initialPhoto: initialPhoto, referenceView: cell)
            
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
            guard let audio = currentAttachment as? Audio else {
                return
            }
            playSound(audio: audio)
        }
        if currentAttachment is TextDocument {
            guard let textDocument = currentAttachment as? TextDocument else {
                return
            }
            self.documentInteractionController = UIDocumentInteractionController.init(url: URL(fileURLWithPath: textDocument.filePath))
            self.documentInteractionController.delegate = self
            self.documentInteractionController.presentPreview(animated: true)
        }
    }
    //swiftlint:enable function_body_length cyclomatic_complexity
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "attachmentCell", for: indexPath) as? CollectionViewCell
        cell?.populateWithAttachment(attachments[(indexPath as NSIndexPath).row].attachment, detail: self, isEdit: modus == Modus.edit ? true : false)
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
            _ = #selector(AttachmentViewController.videoSaved(_:didFinishSavingWithError:context:))
            
            // 2
            //UISaveVideoAtPathToSavedPhotosAlbum(selectedVideo.relativePath, self, selectorToCall, nil)

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
        //UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        
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
