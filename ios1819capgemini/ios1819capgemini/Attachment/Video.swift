import UIKit
import Photos

/// Wrap a PHAsset for video
public class Video {
    var videoPath: String?
    var thumbnailImage: UIImage?
    
    var thumbnailURL: URL?
    
    init(videoPath: String, thumbnailImage: UIImage) {
        self.videoPath = videoPath
        self.thumbnailImage = thumbnailImage
    }
    
    @objc open func loadThumbnailImageWithCompletionHandler(_ completion: @escaping (_ image: UIImage?, _ error: Error?) -> Void) {
        if let thumbnailImage = thumbnailImage {
            completion(thumbnailImage, nil)
            return
        }
        loadThumbnailImageWithURL(thumbnailURL, completion: completion)
    }
    
    open func loadThumbnailImageWithURL(_ url: URL?, completion: @escaping (_ image: UIImage?, _ error: Error?) -> Void) {
        let session = URLSession(configuration: URLSessionConfiguration.default)
        
        if let imageURL = url {
            session.dataTask(with: imageURL, completionHandler: { response, data, error in
                DispatchQueue.main.async(execute: { () -> Void in
                    if error != nil {
                        completion(nil, error)
                    } else if let response = response, let image = UIImage(data: response) {
                        completion(image, nil)
                    } else {
                        completion(nil, NSError(domain: "INSPhotoDomain", code: -1, userInfo: [ NSLocalizedDescriptionKey: "Couldn't load image"]))
                    }
                    session.finishTasksAndInvalidate()
                })
            })
                .resume()
        } else {
            completion(nil, NSError(domain: "INSPhotoDomain", code: -2, userInfo: [ NSLocalizedDescriptionKey: "Image URL not found."]))
        }
    }
}
