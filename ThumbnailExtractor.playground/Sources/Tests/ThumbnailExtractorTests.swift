import XCTest

class ThumbnailExtractorTests: XCTestCase {
    var thumbnailExtractor: ThumbnailExtractor!
    var cacheManager: CacheFileManagerFake!
    
    override func setUp() {
        super.setUp()
        
        clearCacheDirectory()
        
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentsDirectory: String = paths.first!
        
        cacheManager = CacheFileManagerFake(fileManager: .init(), cacheURL: URL(fileURLWithPath: documentsDirectory).appendingPathComponent("Creator-cache"))
        
        do {
            thumbnailExtractor = try ThumbnailExtractor(builder: ThumbnailExtractorBuilder { builder in
                builder.jpegQuality = 90
                builder.maxThumbnailHeight = 250
                builder.cacheFileManager = cacheManager
            })
        }
        catch {
            XCTFail("Wrong error")
        }
    }
    
    override func tearDown() {
        super.tearDown()
        
        thumbnailExtractor = nil
        cacheManager = nil
        clearCacheDirectory()
    }
    
    func testThumbnailExtractorBuilder() {
        XCTAssert(thumbnailExtractor?.jpegQuality == 90, "Thumbnails quality should be set to 90.")
        XCTAssert(thumbnailExtractor?.maxThumbnailHeight == 250, "Max thumbnails size should be 250px height")
    }
    
    func testThumbnailCreatedWithProperSize() {
        let expectation = self.expectation(description: "Thumbnail is created and have size: 445x250")
        
        let testBundle = Bundle(for: type(of: self))
        let url: NSURL = testBundle.url(forResource: "movie2", withExtension: "mov")! as NSURL
        
        thumbnailExtractor?.getThumbnailFrom(url: url.absoluteURL!, success: { data in
            
            let image = NSImage(data: data)
            
            XCTAssertEqual(image!.size.width, 445, "Thumbnail width should be 445px")
            XCTAssertEqual(image!.size.height, 250, "Thumbnail height should be 250px")
            
            expectation.fulfill()
        }, error: { e in
            XCTFail("Unable to create thumbnail")
            expectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 1.0, handler: nil)
    }
    
    func testServedFromCache() {
        let expectation = self.expectation(description: "Test for thumbnail from cache")
        
        let testBundle = Bundle(for: type(of: self))
        let url: NSURL = testBundle.url(forResource: "movie2", withExtension: "mov")! as NSURL
        
        thumbnailExtractor?.getThumbnailFrom(url: url.absoluteURL!, success: { data in
            
            // first call should get thumbnails
            XCTAssert(self.cacheManager.isGetFromCacheCalled == false, "Method getFromCache should not be called.")
            
            self.thumbnailExtractor?.getThumbnailFrom(url: url.absoluteURL!, success: { data in
                
                // second call should return already created thumb
                XCTAssert(self.cacheManager.isGetFromCacheCalled == true, "Method getFromCache should be called.")
                
                expectation.fulfill()
            }, error: { e in
                XCTFail("Unable to create thumbnail")
                expectation.fulfill()
            })
        }, error: { e in
            XCTFail("Unable to create thumbnail")
            expectation.fulfill()
        })
        
        self.waitForExpectations(timeout: 111.0, handler: nil)
    }
    
    func clearCacheDirectory() {
        let paths = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
        let documentsDirectory: String = paths.first!
        
        let fileManager = FileManager.default
        let fileUrls = fileManager.enumerator(at: URL(fileURLWithPath: documentsDirectory).appendingPathComponent("Creator-cache"), includingPropertiesForKeys: nil)
        while let fileUrl = fileUrls?.nextObject() {
            do {
                try fileManager.removeItem(at: fileUrl as! URL)
            } catch {
                print(error)
            }
        }
    }
}
