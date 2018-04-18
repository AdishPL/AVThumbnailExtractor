import Cocoa
import AVFoundation
import Foundation

/**
 Error codes for Thumbnail extractor:
 
 ````
 case cantCreateThumbnailCacheDirectory
 case cantGetName
 case thumbnailCacheDirectoryIsAFile
 case movieFileDoesntExists
 case cantCreateThumbnail
 case cantSaveThumbnail
 ````
 */
public enum ThumbnailExtractorError: Error {
    
    /// Unable to create thumbnail cache directory
    case cantCreateThumbnailCacheDirectory
    
    /// Probably wrong URL, unable to get file's name
    case cantGetName
    
    /// Can't create thumbnail cache directory, given path is a file
    case thumbnailCacheDirectoryIsAFile
    
    /// Wrong URL movie file doesn't exists
    case movieFileDoesntExists
    
    /// Unable to create thumbnail
    case cantCreateThumbnail
    
    /// Unable to save thumbnail
    case cantSaveThumbnail
    
    /// Unable to initialize object
    case cantInitializeObject
}

/**
 Module for extracting thumbnails from the middle of a movie. It will create
 a thumbnail with specified height, width will be adjusted proportionally.
 
 Need to be initialized with builder: `ThumbnailExtractorBuilder`
 
 ### Usage Example: ###
 ````
 do {
 
 let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
 let documentsDirectory: String = paths.first!
 
 let cacheManager = CacheFileManager(fileManager: FileManager.default, cachePathUrl: "\(documentsDirectory)/Creator-cache/")
 
 let thumbnailExtractor = try ThumbnailExtractor(builder: ThumbnailExtractorBuilder { builder in
 builder.jpegQuality = 90
 builder.maxThumbnailHeight = 250
 builder.cacheFileManager = cacheManager
 })
 
 let urls: NSURL = Bundle.main.url(forResource: "movie", withExtension: "mov")! as NSURL
 
 thumbnailExtractor?.getThumbnailFrom(url: urls.absoluteURL!, success: { image in
 let item = image
 }, error: { error in
 print(error)
 })
 
 } catch let error {
 print(error)
 }
 ````
 
 All properties has to be provided to build object using builder, otherwise it
 will return nil.
 */
public class ThumbnailExtractor {
    let jpegQuality: Int?
    let maxThumbnailHeight: Int?
    let cacheFileManager: CacheFileManager?
    
    public init(builder: ThumbnailExtractorBuilder) throws {
        guard let jpegQuality = builder.jpegQuality,
            let maxThumbnailHeight = builder.maxThumbnailHeight,
            let cacheFileManager = builder.cacheFileManager else {
                throw ThumbnailExtractorError.cantInitializeObject
        }
        
        self.jpegQuality = jpegQuality
        self.maxThumbnailHeight = maxThumbnailHeight
        self.cacheFileManager = cacheFileManager
        
        try self.cacheFileManager!.setupCacheDirectory()
    }
    
    /**
     Extracts thumbnail from given URL.
     
     ### Usage Example: ###
     ````
     let urls: NSURL = Bundle.main.url(forResource: "movie", withExtension: "mov")! as NSURL
     
     thumbnailExtractor?.getThumbnailFrom(url: urls.absoluteURL!, success: { image in
     let item = image
     }, error: { error in
     print(error)
     })
     ````
     
     - Parameter URL: URL of a movie.
     - Parameter success: Closure that returns `Data` after successful extraction.
     - Parameter error: Closure that returns `ThumbnailExtractorError` after unsuccessful extraction.
     */
    
    public func getThumbnailFrom(url: URL, success: @escaping (_ thumbnail: Data) -> (),
                                 error: @escaping (_ error: ThumbnailExtractorError) -> ()) {
        
        DispatchQueue.global(qos: .background).async { [weak self] () -> Void in
            guard let weakSelf = self else { return }
            
            guard let itemName = weakSelf.getNameFrom(url: url) else {
                error(.cantGetName)
                return
            }
            
            if let cachedItem = weakSelf.cacheFileManager!.getFromCache(name: itemName) {
                success(cachedItem)
                return
            }
            
            let item = weakSelf.extractFrameFromTheMiddleOf(url: url)
            
            guard let image = item.image, let thumbnail = weakSelf.generateThumbnailFrom(image: image, maxHeight: weakSelf.maxThumbnailHeight!) else {
                error(.cantCreateThumbnail)
                return
            }
            
            if weakSelf.save(image: thumbnail, to: itemName) {
                success(thumbnail)
            }
            else {
                error(.cantSaveThumbnail)
            }
        }
    }
    
    private func getNameFrom(url: URL) -> String? {
        let absoluteString = url.absoluteString
        return absoluteString.md5
    }
    
    private func save(image: Data, to file: String) -> Bool {
        return self.cacheFileManager!.save(data: image, toFileNamed: file)
    }
    
    private func imageJPEGRepresentation(image: NSImage) -> NSData? {
        if let imageTiffData = image.tiffRepresentation, let imageRep = NSBitmapImageRep(data: imageTiffData) {
            let imageProps = [NSBitmapImageRep.PropertyKey.compressionFactor: self.jpegQuality!]
            let imageData = imageRep.representation(using: NSBitmapImageRep.FileType.jpeg, properties: imageProps) as NSData?
            return imageData
        }
        
        return nil
    }
    
    private func generateThumbnailFrom(image: NSImage, maxHeight: Int) -> Data? {
        if image.size.height <= CGFloat(maxHeight) {
            return image.tiffRepresentation
        }
        
        let thumbnail = image.resizeImage(height: CGFloat(self.maxThumbnailHeight!))
        
        return thumbnail.tiffRepresentation
    }
    
    private func extractFrameFromTheMiddleOf(url: URL) -> (image: NSImage?, error: NSError?) {
        let asset: AVAsset = AVAsset(url: url)
        let duration = asset.duration
        let assetImgGenerate : AVAssetImageGenerator = AVAssetImageGenerator(asset: asset)
        let error: NSError? = nil
        
        let time = CMTime(value: duration.value / 2, timescale: duration.timescale)
        var image: CGImage? = nil
        
        assetImgGenerate.appliesPreferredTrackTransform = true
        assetImgGenerate.requestedTimeToleranceAfter = kCMTimeZero;
        assetImgGenerate.requestedTimeToleranceBefore = kCMTimeZero;
        
        do {
            image = try assetImgGenerate.copyCGImage(at: time, actualTime: nil)
        } catch let error as NSError {
            return (nil, error)
        }
        
        if let img = image {
            return (NSImage(cgImage: img, size: NSSize(width: img.width, height: img.height)), error)
        }
        
        return (nil, error)
    }
    
    private func resolutionSizeForLocalVideo(url: URL) -> CGSize? {
        guard let track = AVAsset(url: url).tracks(withMediaType: AVMediaType.video).first else { return nil }
        let size = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: fabs(size.width), height: fabs(size.height))
    }
}
