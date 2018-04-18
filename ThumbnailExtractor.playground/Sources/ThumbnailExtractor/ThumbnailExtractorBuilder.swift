import Foundation

/**
 * Builder for ThumbnailExtractor class. All fields are required.
 */

public class ThumbnailExtractorBuilder {
    
    /// Quality of thumbnail jpeg file. Range 0..100
    public var jpegQuality: Int?
    
    /// Maximum height of thumbnail image. Width will be calculated to maitain aspect ratio.
    public var maxThumbnailHeight: Int?
    
    /// Cache manager - (dependency)
    public var cacheFileManager: CacheFileManager?
    
    public typealias BuilderClosure = (ThumbnailExtractorBuilder) -> Void
    
    public init(buildClosure: BuilderClosure) {
        buildClosure(self)
    }
}
