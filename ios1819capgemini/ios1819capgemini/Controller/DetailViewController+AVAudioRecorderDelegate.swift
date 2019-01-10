//
//  DetailViewController+AVAudioRecorderDelegate.swift
//  ios1819capgemini
//
//  Created by MembrainDev on 19.12.18.
//  Copyright © 2018 TUM LS1. All rights reserved.
//

import Foundation
import AVKit

extension DetailViewController: AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    
    public func startRecording() {
        let defaults = UserDefaults.standard
        let audioFilename = getDocumentsDirectory().appendingPathComponent("cARgeminiAudioAsset\(defaults.integer(forKey: "AttachedAudioName")).m4a")
        defaults.set(defaults.integer(forKey: "AttachedAudioName") + 1, forKey: "AttachedAudioName")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 12000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            guard let delegate = self as? AVAudioRecorderDelegate else {
                return
            }
            audioRecorder.delegate = delegate
            audioRecorder.record()
            recordButton.setTitle("Tap to Stop", for: .normal)
        } catch {
            finishRecording(success: false)
        }
    }
    
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            finishRecording(success: false)
        }
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        audioPlayer?.stop()
        audioPlayer = nil
    }
    
    func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func playSound(audio: Audio) {
        let url = URL(fileURLWithPath: audio.filePath)
        do {
            //try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            /* The following line is required for the player to work on iOS 11. Change the file type accordingly*/
            audioPlayer = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileType.mp3.rawValue)
            audioPlayer?.delegate = self
            /* iOS 10 and earlier require the following line:
             player = try AVAudioPlayer(contentsOf: url, fileTypeHint: AVFileTypeMPEGLayer3) */
            
            guard let audioPlayer = audioPlayer else {
                return
            }
            
            audioPlayer.play()
        } catch let error {
            print(error)
            print(error.localizedDescription)
        }
    }
    
    
}
