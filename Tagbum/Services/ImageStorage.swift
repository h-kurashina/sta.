import UIKit
import ImageIO

actor ImageStorage {
    static let shared = ImageStorage()
    private let cache = NSCache<NSString, UIImage>()

    init() { cache.totalCostLimit = 48 * 1024 * 1024 }

    func write(_ items: [Data], root: URL) throws -> [String] {
        var paths: [String] = []
        do {
            for data in items {
                guard let image = UIImage(data: data), let jpeg = image.jpegData(compressionQuality: 0.92) else {
                    throw CocoaError(.fileReadCorruptFile)
                }
                let path = "\(UUID().uuidString).jpg"
                try jpeg.write(to: root.appending(path: path), options: .atomic)
                paths.append(path)
            }
            return paths
        } catch {
            for path in paths { try? FileManager.default.removeItem(at: root.appending(path: path)) }
            throw error
        }
    }

    func image(at url: URL, maxPixel: Int) -> UIImage? {
        let key = "\(url.path)-\(maxPixel)" as NSString
        if let image = cache.object(forKey: key) { return image }
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: maxPixel
              ] as CFDictionary) else { return nil }
        let image = UIImage(cgImage: cgImage)
        cache.setObject(image, forKey: key, cost: cgImage.bytesPerRow * cgImage.height)
        return image
    }
}
