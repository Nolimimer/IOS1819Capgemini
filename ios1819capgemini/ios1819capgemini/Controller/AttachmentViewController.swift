//
//  AttachmentViewController.swift
//  ios1819capgemini
//
//  Created by MembrainDev on 02.12.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

import Foundation
import UIKit
import AVKit
import MobileCoreServices
import INSPhotoGallery


class AttachmentViewController: UIViewController, UINavigationControllerDelegate {
    //@IBOutlet var view: UIView!
    // swiftlint:disable implicitly_unwrapped_optional
    var imagePicker: UIImagePickerController!
    var recordButton: UIButton!
    var audioRecorder: AVAudioRecorder!
    
    @IBOutlet private weak var videoCollectionView: UICollectionView!
    @IBOutlet private weak var photoCollectionView: UICollectionView!
    @IBOutlet private weak var photoButton: UIBarButtonItem!
    @IBOutlet private weak var toolbar: UIToolbar!
    @IBOutlet private var mainView: UIView!
    
    
    var photos: [PhotoWrapper] = []
    var videos: [Video] = []
    
    
    // MARK: override methods
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        photos = computePhotos()
        self.videos = computeVideos()
        videoCollectionView.delegate = self
        videoCollectionView.dataSource = self
        videoCollectionView.reloadData()
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        photoCollectionView.reloadData()
        self.photoCollectionView.isPagingEnabled = true
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.frame = UIScreen.main.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        self.parent?.navigationController?.view.addSubview(blurView)
        self.parent?.navigationController?.view.sendSubviewToBack(blurView)
        view.addSubview(blurView)
        view.sendSubviewToBack(blurView)
        //toolbar.addSubview(blurView)
        //toolbar.sendSubviewToBack(blurView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        photos = computePhotos()
        videos = computeVideos()
        videoCollectionView.reloadData()
        photoCollectionView.reloadData()
        
        var items = toolbar.items
        items?[0] = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.camera, target: self, action: #selector(takePhoto(_:)))
        toolbar.setItems(items, animated: false)

        self.modalPresentationStyle = .overCurrentContext
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .bottom, barMetrics: .default)
    }
    
    // MARK: IBActions
    @IBAction private func takeVideo(_ sender: Any) {
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
        imagePicker.sourceType = .camera
        imagePicker.mediaTypes = [kUTTypeMovie as String]
        present(imagePicker, animated: true, completion: nil)
    }
    
    @IBAction private func deleteAll(_ sender: Any) {
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            
            let fileManager = FileManager.default
            do {
                let filePaths = try fileManager.contentsOfDirectory(atPath: dir.path)
                for filePath in filePaths {
                    let fullPath = URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(filePath).path

                    if fileManager.fileExists(atPath: fullPath) {
                        do {
                            try fileManager.removeItem(atPath: fullPath)
                        } catch {
                            print ("Error deleting file")
                        }
                    } else {
                        print("File does not exist")
                    }
                }
            } catch {
                    print("Error deleting file")
            }
        }
        photos = []
        videos = []
        photoCollectionView.reloadData()
        videoCollectionView.reloadData()
    }
    
    @IBAction private func takePhoto(_ sender: Any) {
        imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
    }
    
    func computePhotos() -> [PhotoWrapper] {
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            
            let fileManager = FileManager.default
            let arrImages: NSMutableArray = []
            do {
                let filePaths = try fileManager.contentsOfDirectory(atPath: dir.path)
                for filePath in filePaths {
                    let urlString = URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(filePath).path
                    if urlString.hasSuffix("jpg") {
                        arrImages.add(urlString)
                    }
                    
                }
            } catch {
                print("Could not get folder: \(error)")
            }
            var result: [PhotoWrapper] = []
            
            for val in arrImages {
                guard let val = val as? String else {
                    continue
                }
                let strings = val.split(separator: "/")
                result.append(PhotoWrapper(photo: Photo(name: String(strings[strings.count - 1]), photoPath: val)))
            }
            return result
        }
        return []
    }
    
    func computeVideos() -> [Video] {
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            
            let fileManager = FileManager.default
            let arrImages: NSMutableArray = []
            do {
                let filePaths = try fileManager.contentsOfDirectory(atPath: dir.path)
                for filePath in filePaths {
                    let urlString = URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(filePath).path
                    if urlString.hasSuffix("mov") {
                        arrImages.add(urlString)
                    }
                }
            } catch {
                print("Could not get folder: \(error)")
            }
            let result: [Video] = []
            for val in arrImages {
                guard val is String else {
                    continue
                }
                //result.append(Video(name: String(name), videoPath: val, duration: ))
            }
            return result
        }
        return []
    }
    
    func getSavedImage(named: String) -> UIImage? {
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            return UIImage(contentsOfFile: URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(named).path)
        }
        return nil
    }
    
    @objc func videoSaved(_ video: String, didFinishSavingWithError error: NSError!, context: UnsafeMutableRawPointer) {
        if let theError = error {
            print("error saving the video = \(theError)")
        } else {
            DispatchQueue.main.async(execute: { () -> Void in })
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let alertController = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            present(alertController, animated: true)
        } else {
            let alertController = UIAlertController(title: "Saved!",
                                                    message: "Your altered image has been saved to your photos.",
                                                    preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "OK", style: .default))
            present(alertController, animated: true)
        }
    }
}

extension AttachmentViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.videoCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "VideoCollectionViewCell", for: indexPath) as? VideoCollectionViewCell
            cell?.populateWithVideo(videos[(indexPath as NSIndexPath).row])
            return cell ?? UICollectionViewCell()
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ExampleCell", for: indexPath) as? ExampleCollectionViewCell
            cell?.populateWithPhoto(photos[(indexPath as NSIndexPath).row])
            
            return cell ?? UICollectionViewCell()
        }
        
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.videoCollectionView {
            return videos.count
        }
        return photos.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.videoCollectionView {
            let item = videos[(indexPath as NSIndexPath).item]
            let player = AVPlayer(url: URL(fileURLWithPath: item.filePath))
            let playerController = AVPlayerViewController()
            playerController.player = player
            present(playerController, animated: true) {
                player.play()
            }
            return
        }
        let cell = collectionView.cellForItem(at: indexPath) as? ExampleCollectionViewCell
        let currentPhoto = photos[(indexPath as NSIndexPath).row]
        let galleryPreview = INSPhotosViewController(photos: photos, initialPhoto: currentPhoto, referenceView: cell)
        
        galleryPreview.referenceViewForPhotoWhenDismissingHandler = { [weak self] photo in
            if let index = self?.photos.index(where: { $0 === photo }) {
                let indexPath = IndexPath(item: index, section: 0)
                return  collectionView.cellForItem(at: indexPath) as? ExampleCollectionViewCell
            }
            return nil
        }
        present(galleryPreview, animated: true, completion: nil)
    }
}
