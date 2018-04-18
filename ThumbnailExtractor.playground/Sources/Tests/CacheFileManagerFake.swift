import Foundation

class CacheFileManagerFake: CacheFileManager {
    var isGetFromCacheCalled = false
    
    public override func getFromCache(name: String) -> Data? {
        let itemFromCache = super.getFromCache(name: name)
        
        self.isGetFromCacheCalled = (itemFromCache != nil) ? true : false
        
        return itemFromCache
    }
}
