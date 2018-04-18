import Foundation

extension String {
    var md5: String? {
        let t = Process()
        t.launchPath = "/sbin/md5"
        t.arguments = ["-q", "-s", self]
        t.standardOutput = Pipe()
        
        t.launch()
        
        let outData = (t.standardOutput as! Pipe).fileHandleForReading.readDataToEndOfFile()
        let outBytes = [UInt8](repeating:0, count:outData.count)
        
        let outString = String(bytes: outBytes, encoding: .ascii)
        
        return outString?.trimmingCharacters(in: .newlines)
    }
}

