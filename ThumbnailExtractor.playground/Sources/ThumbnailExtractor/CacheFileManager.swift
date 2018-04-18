import Foundation

/**
 Class for managing cache.
 */

public class CacheFileManager {
    
    let fileManager: FileManager
    let cacheURL: URL
    
    let thumbnailExtension = "jpg"
    
    /**
     Initialize Cache file manager with dependencies:
     
     - Parameter fileManager: File manager library.
     - Parameter cacheURL: URL path to cache directory.
     */
    
    public init(fileManager: FileManager, cacheURL: URL) {
        self.fileManager = fileManager
        self.cacheURL = cacheURL
    }
    
    /**
     Create new cache directory if there is no directory yet.
     - throws: If there will be an error, it will throw ThumbnailExtractorError.
     */
    public func setupCacheDirectory() throws {
        var isDir: ObjCBool = false
        
        if !fileManager.fileExists(atPath: cacheURL.absoluteString, isDirectory: &isDir) {
            do {
                try fileManager.createDirectory(atPath: cacheURL.absoluteString, withIntermediateDirectories: true, attributes: nil)
            } catch {
                throw ThumbnailExtractorError.cantCreateThumbnailCacheDirectory
            }
        } else {
            if !isDir.boolValue {
                throw ThumbnailExtractorError.thumbnailCacheDirectoryIsAFile
            }
        }
    }
    
    /**
     Saves data to file.
     
     - Parameters:
     - data: NSData to be saved.
     - file: Name of a file that will hold cache data.
     - Returns: `true` if `save` is successful, false otherwise
     */
    public func save(data: Data, toFileNamed  filename: String) -> Bool {
        
        do {
            let url = generateFileURL(filename: filename)
            try data.write(to: url, options: .atomic)
            
            return true
        } catch {
            return false
        }
    }
    
    /**
     Returns cache data from file.
     
     - Parameters:
     - name: Name of a file that holds data.
     - Returns: `Data` if cache exists, `nil` otherwise
     */
    public func getFromCache(name: String) -> Data? {
        do {
            return try Data(contentsOf: generateFileURL(filename: name))
        }
        catch {
            return nil
        }
    }
    
    private func generateFileURL(filename: String) -> URL {
        return cacheURL.appendingPathComponent(filename).appendingPathExtension(thumbnailExtension)
    }
}
