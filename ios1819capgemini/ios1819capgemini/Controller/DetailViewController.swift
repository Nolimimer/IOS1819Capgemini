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

// MARK: - DetailViewController
class DetailViewController: UIViewController, UINavigationControllerDelegate {
    
    private var modus = Modus.view
    var recordButton: UIButton!
    var recordingSession: AVAudioSession!
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer?
    
    private var dateFormatter: DateFormatter {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy HH:mm"
        return dateFormatter
    }
    
    // Variables / Mock Variable
    var incident = Incident(type: IncidentType.dent,
                            description: "This scratch is a critical one, my suggestion is to completly remove the right door.",
                            coordinate: Coordinate (vector: SCNVector3(0, 0, 0)))
    var attachments: [Attachment] = []
    var imagePicker: UIImagePickerController!

    // MARK: IBOutlets
    @IBOutlet private weak var navigationItemIncidentTitle: UINavigationItem!
    @IBOutlet private weak var generatedDateLabel: UILabel!
    @IBOutlet private weak var lastModifiedDateLabel: UILabel!
    @IBOutlet private weak var collectionView: UICollectionView!
    @IBOutlet private weak var segmentControll: UISegmentedControl!
    @IBOutlet private weak var backButton: UIBarButtonItem!
    @IBOutlet private weak var textField: UITextView!
    @IBOutlet private weak var editButton: UIBarButtonItem!
    
    // MARK: IBActions
    @IBAction private func backButtonPressed(_ sender: Any) {
         self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func showAllAttachments(_ sender: Any) {
        performSegue(withIdentifier: "attachmentSegue", sender: self)
    }
    
    @IBAction private func editButtonPressed(_ sender: Any) {
        switch modus {
        case .view:
            editButton.title = "Save"
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
            incident.edit(status: status, description: textField.text, modifiedDate: Date())
            
            editButton.title = "Edit"
            textField.isEditable = false
            segmentControll.isEnabled = false
            textField.layer.borderWidth = 0.0
            lastModifiedDateLabel.text = dateFormatter.string(from: incident.modifiedDate)
            
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
        modalPresentationStyle = .overCurrentContext
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        
        navigationItemIncidentTitle.title = "\(incident.type.rawValue) \(incident.identifier)"
        
        let controllIndex: Int
        switch incident.status {
        case .open:
            controllIndex = 0
        case .progress:
            controllIndex = 1
        case .resolved:
            controllIndex = 2
        }
        segmentControll.selectedSegmentIndex = controllIndex
        
        let dateString = dateFormatter.string(from: incident.createDate)
        let lastModifiedDateString = dateFormatter.string(from: incident.modifiedDate)
        generatedDateLabel.text = dateString
        lastModifiedDateLabel.text = lastModifiedDateString
        textField.text = incident.description
        attachments = []
        attachments.append(Photo(name: "plusButton", photoPath: "errorPath"))
        attachments.append(contentsOf: (incident.attachments))
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
        attachments.append(contentsOf: (incident.attachments))
        
//        let gesture = UITapGestureRecognizer(target: self, action:  #selector (self.handleTap(recognizer:)))
//        self.view.addGestureRecognizer(gesture)
        // add blurred subview
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = UIScreen.main.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.navigationController?.view.addSubview(blurView)
        self.navigationController?.view.sendSubviewToBack(blurView)
    }
    
    func hidePopup() {
        for child in view.subviews {
            if child is AttachmentView {
                child.removeFromSuperview()
            }
        }
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
            incident.addAttachment(attachment: Audio(name: name, filePath: "\(paths[0])/\(name)", duration: duration))
            recordButton.setTitle("Audio", for: .normal)
            hidePopup()
            attachments = []
            attachments.append(Photo(name: "plusButton", photoPath: "errorPath"))
            attachments.append(contentsOf: (incident.attachments))
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
}

// MARK: Extension
extension DetailViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return attachments.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if (indexPath as NSIndexPath).row == 0 {
            let attachmentView = AttachmentView(frame: CGRect(x: collectionView.cellForItem(at: indexPath)!.center.x - 30,
                                                              y: collectionView.center.y - 200,
                                                              width: 150,
                                                              height: 200))
            attachmentView.photoButton.addTarget(self, action: #selector(takePhoto), for: .touchUpInside)
             attachmentView.videoButton.addTarget(self, action: #selector(takeVideo), for: .touchUpInside)
             attachmentView.audioButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
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
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "attachmentCell", for: indexPath) as? CollectionViewCell
        cell?.populateWithAttachment(attachments[(indexPath as NSIndexPath).row])
        return cell ?? UICollectionViewCell()
    }
}

extension DetailViewController: UIImagePickerControllerDelegate {
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
                incident.addAttachment(attachment: Video(name: name, videoPath: "\(paths[0])/\(name)", duration: 3.0))
            } catch {
                print(Error.self)
            }
        }
    }
    
    @objc func videoSaved(_ video: String, didFinishSavingWithError error: NSError!, context: UnsafeMutableRawPointer) {
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
            incident.addAttachment(attachment: Photo(name: name, photoPath: "\(paths[0])/\(name)"))
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
}

// MARK: Constants
enum Modus {
    case view
    case edit
}
