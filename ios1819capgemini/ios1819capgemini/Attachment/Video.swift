import UIKit
import Photos

/// Wrap a PHAsset for video
public class Video: Attachment {
    
    init(name: String, videoPath: String) {
        super.init(name: name, filePath: videoPath)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
}
