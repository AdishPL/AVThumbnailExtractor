import Cocoa

extension NSImage {
    func resizeImage(height: CGFloat) -> NSImage {
        let newWidth = ceil(height * (self.size.width / self.size.height))
        
        let newSize = NSSize(width: newWidth, height: height)
        if let bitmapRep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: Int(newWidth), pixelsHigh: Int(height), bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: NSColorSpaceName.calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0) {
            bitmapRep.size = newSize
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
            self.draw(in: NSRect(x: 0, y: 0, width: newWidth, height: height), from: NSZeroRect, operation: .copy, fraction: 1.0)
            NSGraphicsContext.restoreGraphicsState()
            
            let resizedImage = NSImage(size: newSize)
            resizedImage.addRepresentation(bitmapRep)
            return resizedImage
        }
        return self
    }
}
