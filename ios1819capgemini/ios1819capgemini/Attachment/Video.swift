import UIKit
import Photos

/// Wrap a PHAsset for video
public class Video: Attachment {
    
    let duration: TimeInterval
    
    init(name: String, videoPath: String, duration: TimeInterval) {
        self.duration = duration
        super.init(name: name, filePath: videoPath)
    }
    
    required init(from decoder: Decoder) throws {
        self.duration = 0.0
        try super.init(from: decoder)
    }
    
    override func computeThumbnail() -> UIImage {
        guard let createdThumbnail = createThumbnailOfVideoFromRemoteUrl(url: filePath) else {
            guard let result = UIImage(named: "videoPreview") else {
                return UIImage()
            }
            return result
        }
        return createdThumbnail
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
