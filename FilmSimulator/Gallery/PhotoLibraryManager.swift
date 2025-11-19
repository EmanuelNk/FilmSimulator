import Photos
import UIKit

class PhotoLibraryManager {
    static let shared = PhotoLibraryManager()
    
    func savePhoto(image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized || status == .limited else {
                completion(false, nil)
                return
            }
            
            PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            } completionHandler: { success, error in
                completion(success, error)
            }
        }
    }
    
    // Future: Save RAW + JPEG
    // This requires writing files to disk first and then adding them as a resource.
}
