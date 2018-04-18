import Cocoa

do {
    let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
    let documentsDirectory = paths.first!
    
    let cacheManager = CacheFileManager(fileManager: .default, cacheURL: URL(fileURLWithPath: documentsDirectory).appendingPathComponent("Creator-cache"))
    

    let thumbnailExtractor = try ThumbnailExtractor(builder: ThumbnailExtractorBuilder { builder in
        builder.jpegQuality = 90
        builder.maxThumbnailHeight = 250
        builder.cacheFileManager = cacheManager
    })
    
    let urls: NSURL = Bundle.main.url(forResource: "movie", withExtension: "mov")! as NSURL
    
    thumbnailExtractor.getThumbnailFrom(url: urls.absoluteURL!, success: { image in
        let item = image
    }, error: { error in
        print(error)
    })
    
} catch let error {
    print(error)
}
