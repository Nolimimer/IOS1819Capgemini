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
    
    var imagePicker: UIImagePickerController!
    var recordButton: UIButton!
    var audioRecorder: AVAudioRecorder!
    
    @IBOutlet weak var videoCollectionView: UICollectionView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var photoButton: UIBarButtonItem!
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet var mainView: UIView!
    
    
    var photos: [INSPhotoViewable] = []
    var videos: [Video] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        photos = computePhotos()

        self.videos = computeVideos()
        let videos = self.videos
        for photo in photos {
            if let photo = photo as? INSPhoto {
                photo.attributedTitle = NSAttributedString(string: "Example caption text\ncaption text",
                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])

            }
        }
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
        self.modalPresentationStyle = .overCurrentContext
        toolbar.setItems(items, animated: false)
        toolbar.setBackgroundImage(UIImage(), forToolbarPosition: .bottom, barMetrics: .default)
    }
    
    
    
    
    @IBAction func loadPhoto(_ sender: Any) {
        guard let ass = getSavedImage(named: "fileName.png") else {
            return
        }
    }
    
    @IBAction func takePhoto(_ sender: Any) {
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    @IBAction func recordAudio(_ sender: Any) {
        let recordingSession = AVAudioSession.sharedInstance()
        
        do {
            try recordingSession.setCategory(.playAndRecord, mode: .default)
            try recordingSession.setActive(true)
            recordingSession.requestRecordPermission() { [unowned self] allowed in
                DispatchQueue.main.async {
                    if allowed {
                        self.loadRecordingUI()
                    } else {
                        // failed to record!
                    }
                }
            }
        } catch {
            // failed to record!
        }
    }
    
    func loadRecordingUI() {
        recordButton = UIButton(frame: CGRect(x: 64, y: 64, width: 128, height: 64))
        recordButton.setTitle("Tap to Record", for: .normal)
        recordButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .title1)
        recordButton.addTarget(self, action: #selector(recordTapped), for: .touchUpInside)
        view.addSubview(recordButton)
    }
    
    func finishRecording(success: Bool) {
        audioRecorder.stop()
        audioRecorder = nil
        
        if success {
            recordButton.setTitle("Tap to Re-record", for: .normal)
        } else {
            recordButton.setTitle("Tap to Record", for: .normal)
            // recording failed :(
        }
    }
    
    @objc func recordTapped() {
        if audioRecorder == nil {
          //  startRecording()
        } else {
            finishRecording(success: true)
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
    
    func computePhotos() -> [INSPhotoViewable] {
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            
            let fileManager = FileManager.default
            let arrImages : NSMutableArray = []
            do {
                let filePaths = try fileManager.contentsOfDirectory(atPath: dir.path)
                for filePath in filePaths {
                    let urlString = URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(filePath).path
                    if urlString.hasSuffix("jpg"){
                        try arrImages.add(urlString)
                    }
                    
                }
            } catch {
                print("Could not get folder: \(error)")
            }
            var result: [INSPhoto] = []
            for val in arrImages {
                guard let val = val as? String else {
                    continue
                }
                result.append(INSPhoto(image: UIImage(contentsOfFile: val), thumbnailImage: UIImage(contentsOfFile: val)))
            }
            return result
        }
        return []
    }
    
    func computeVideos() -> [Video] {
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            
            let fileManager = FileManager.default
            let arrImages : NSMutableArray = []
            do {
                let filePaths = try fileManager.contentsOfDirectory(atPath: dir.path)
                for filePath in filePaths {
                    let urlString = URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(filePath).path
                    if urlString.hasSuffix("mov"){
                        try arrImages.add(urlString)
                    }

                }
            } catch {
                print("Could not get folder: \(error)")
            }
            var result: [Video] = []
            for val in arrImages {
                guard let val = val as? String else {
                    continue
                }
                let thumbnail = createThumbnailOfVideoFromRemoteUrl(url: val)
                result.append(Video(videoPath: val, thumbnailImage: thumbnail ?? UIImage()))
            }
            return result
        }
        return []
    }
    
    @IBAction func takeVideo(_ sender: Any) {
        imagePicker =  UIImagePickerController()
        imagePicker.delegate = self as? UIImagePickerControllerDelegate & UINavigationControllerDelegate
        imagePicker.sourceType = .camera
        imagePicker.mediaTypes = [kUTTypeMovie as String]
        present(imagePicker, animated: true, completion: nil)
    }
    
    
    private func saveImage(image: UIImage) -> Bool {
        UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        
        let paths = NSSearchPathForDirectoriesInDomains(
            FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentsDirectory: URL = URL(fileURLWithPath: paths[0])
        
        guard let data = image.jpegData(compressionQuality: 1) ?? image.jpegData(compressionQuality: 0.5) else {
            return false
        }
        guard let directory = try? FileManager.default.url(for: .documentDirectory,
                                                           in: .userDomainMask,
                                                           appropriateFor: nil,
                                                           create: false) as NSURL else {
            return false
        }
        do {
            let defaults = UserDefaults.standard
            try data.write(to: documentsDirectory.appendingPathComponent("cARgeminiasset\(defaults.integer(forKey: "AttachedPhotoName")).jpg"), options:[])
            defaults.set(defaults.integer(forKey: "AttachedPhotoName") + 1, forKey: "AttachedPhotoName")
            return true
        } catch {
            print(error.localizedDescription)
            return false
        }
    }
    
    @objc func videoSaved(_ video: String, didFinishSavingWithError error: NSError!, context: UnsafeMutableRawPointer){
        if let theError = error {
            print("error saving the video = \(theError)")
        } else {
            DispatchQueue.main.async(execute: { () -> Void in
            })
        }
    }
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            // we got back an error!
            let ac = UIAlertController(title: "Save error", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "Saved!", message: "Your altered image has been saved to your photos.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            present(ac, animated: true)
        }
    }
    
    
    
    func getSavedImage(named: String) -> UIImage? {
        if let dir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            return UIImage(contentsOfFile: URL(fileURLWithPath: dir.absoluteString).appendingPathComponent(named).path)
        }
        return nil
    }
    
    func createThumbnailOfVideoFromRemoteUrl(url: String) -> UIImage? {
       
        let asset = AVURLAsset(url: URL(fileURLWithPath: url), options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        
        
        //Can set this to improve performance if target size is known before hand
        //assetImgGenerate.maximumSize = CGSize(width,height)
        var time = CMTimeMakeWithSeconds(1.0, preferredTimescale: 600)
        do {
            imgGenerator.appliesPreferredTrackTransform = true
            let cgImage = try imgGenerator.copyCGImage(at: CMTimeMake(value: 0, timescale: 1), actualTime: nil)
            let thumbnail = UIImage(cgImage: cgImage)
            return thumbnail
        } catch {
            print(error)
            return nil
        }
    }
    
}



extension AttachmentViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        //swiftlint:disable
        if(collectionView == self.videoCollectionView) {
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
        if(collectionView == self.videoCollectionView) {
            return videos.count
        }
        return photos.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if(collectionView == self.videoCollectionView) {
            let item = videos[(indexPath as NSIndexPath).item]
            guard let path = item.videoPath else {
                return
            }
            let player = AVPlayer(url: URL(fileURLWithPath: path))
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

extension AttachmentViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
        imagePicker.dismiss(animated: true, completion: nil)
        if let selectedImage = info[.originalImage] as? UIImage {
            if(saveImage(image: selectedImage)) {
                print("Saved image")
            }
        }
        
        if let selectedVideo:URL = (info[UIImagePickerController.InfoKey.mediaURL] as? URL) {
            // Save video to the main photo album
            let selectorToCall = #selector(AttachmentViewController.videoSaved(_:didFinishSavingWithError:context:))
            
            // 2
            UISaveVideoAtPathToSavedPhotosAlbum(selectedVideo.relativePath, self, selectorToCall, nil)
            // Save the video to the app directory
            let videoData = try? Data(contentsOf: selectedVideo)
            let paths = NSSearchPathForDirectoriesInDomains(
                FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            let documentsDirectory: URL = URL(fileURLWithPath: paths[0])
            let defaults = UserDefaults.standard
            let dataPath = documentsDirectory.appendingPathComponent("cARgeminiVideoAsset\(defaults.integer(forKey: "AttachedVideoName")).mov")
             defaults.set(defaults.integer(forKey: "AttachedVideoName") + 1, forKey: "AttachedVideoName")
            do {
                try videoData?.write(to: dataPath, options: [])
            }
            catch is Error {
                print(Error.self)
            }
        }
    }
    
}

class ExampleCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    
    func populateWithPhoto(_ photo: INSPhotoViewable) {
        photo.loadThumbnailImageWithCompletionHandler { [weak photo] (image, error) in
            if let image = image {
                if let photo = photo as? INSPhoto {
                    photo.thumbnailImage = image
                }
                self.imageView.image = image
            }
        }
    }
}

class VideoCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    
    func populateWithVideo(_ video: Video) {
        video.loadThumbnailImageWithCompletionHandler { [weak video] (image, error) in
            if let image = image {
                if let video = video as? Video {
                    video.thumbnailImage = image
                }
                let frontimg = UIImage(named: "play") // The image in the foreground
                let frontimgview = UIImageView(image: frontimg) // Create the view holding the image
                self.imageView.image = image
                self.imageView.addSubview(frontimgview)

            }
        }
    }
}

