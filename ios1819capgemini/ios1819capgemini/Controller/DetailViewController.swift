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
import SceneKit

// MARK: - DetailViewController
class DetailViewController: UIViewController {
    
    private var modus = Modus.view
    
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
        attachments = computeAttachments()
        collectionView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        attachments = computeAttachments()
        // add blurred subview
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = UIScreen.main.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.navigationController?.view.addSubview(blurView)
        self.navigationController?.view.sendSubviewToBack(blurView)
    }
    
    func computeAttachments() -> [Attachment] {
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            
            let fileManager = FileManager.default
            let arrImages: NSMutableArray = []
            do {
                let filePaths = try fileManager.contentsOfDirectory(atPath: dir.path)
                for filePath in filePaths {
                    let urlString = URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(filePath).path
                        arrImages.add(urlString)
                }
            } catch {
                print("Could not get folder: \(error)")
            }
            var result: [Attachment] = []
            result.append(Photo(name: "plusButton", photoPath: "errorPath"))
            for val in arrImages {
                guard let val = val as? String else {
                    continue
                }
                let strings = val.split(separator: "/")
                let name = strings[strings.count - 1]
                if val.hasSuffix("mov") {
                    result.append(Video(name: String(name), videoPath: val))
                    continue
                }
                if val.hasSuffix("jpg") {
                    result.append(Photo(name: String(name), photoPath: val))
                }
            }
            result.sort {
                $0.date == $1.date
            }
            return result
        }
        return []
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
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "attachmentCell", for: indexPath) as? CollectionViewCell
        cell?.populateWithAttachment(attachments[(indexPath as NSIndexPath).row])
        return cell ?? UICollectionViewCell()
        // Just for testing/mocking // TODO
      
    }
}

// MARK: Constants
enum Modus {
    case view
    case edit
}
