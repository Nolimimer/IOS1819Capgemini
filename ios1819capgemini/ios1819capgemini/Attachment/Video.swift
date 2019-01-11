import UIKit
import Photos

/// Wrap a PHAsset for video
class Video: Attachment {
    
    static let type = AttachmentType.video
    
    var data: Data?
    
    var identifier: Int
    
    var date: Date
    
    var filePath: String
    
    var name: String
    
    
    let duration: TimeInterval
    
    init(name: String, videoPath: String, duration: TimeInterval) {
        self.duration = duration
        date = Date()
        self.name = name
        self.filePath = videoPath
        let defaults = UserDefaults.standard
        identifier = defaults.integer(forKey: "AttachmentIdentifer")
        defaults.set(defaults.integer(forKey: "AttachmentIdentifer") + 1, forKey: "AttachmentIdentifer")
        reevaluatePath()
    }
    
    func computeThumbnail() -> UIImage {
        guard let createdThumbnail = createThumbnailOfVideoFromRemoteUrl(url: filePath) else {
            guard let result = UIImage(named: "videoPreview") else {
                return UIImage()
            }
            return result
        }
        return createdThumbnail
    }
    
    func reevaluatePath() {
        do {
            let paths = NSSearchPathForDirectoriesInDomains(
                FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            let documentsDirectory = URL(fileURLWithPath: paths[0])
            let path = documentsDirectory.appendingPathComponent(name)
            guard let data = data else {
                return
            }
            try data.write(to: path, options: [])
            filePath = path.absoluteString
        } catch {
            data = nil
        }
    }
    
    private func createThumbnailOfVideoFromRemoteUrl(url: String) -> UIImage? {
        
        let asset = AVURLAsset(url: URL(fileURLWithPath: url), options: nil)
        let imgGenerator = AVAssetImageGenerator(asset: asset)
        
        
        //Can set this to improve performance if target size is known before hand
        //assetImgGenerate.maximumSize = CGSize(width,height)
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
