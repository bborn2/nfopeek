import Foundation
import ImageIO
import UniformTypeIdentifiers

/// Collects downsampled local images as Quick Look attachments. Each `cid:<id>` in HTML maps to one.
final class ImageStore {
    private(set) var images: [String: Data] = [:]
    private var idsBySource: [String: String] = [:]
    private var idsByContent: [Data: String] = [:]
    private var originalIds: [String: String] = [:]
    private let baseDir: URL

    init(baseDir: URL) { self.baseDir = baseDir }

    private func resolve(_ path: String) -> URL? {
        guard !path.contains("://") else { return nil }
        return path.hasPrefix("/") ? URL(fileURLWithPath: path) : baseDir.appendingPathComponent(path)
    }

    /// Attaches the original file bytes untouched (no downsampling or re-encoding), returns attachment id.
    /// Used for the full-size lightbox view.
    @discardableResult
    func loadOriginal(_ path: String) -> String? {
        guard let url = resolve(path) else { return nil }
        let key = url.standardizedFileURL.path
        if let id = originalIds[key] { return id }
        guard let data = try? Data(contentsOf: url) else { return nil }
        let ext = url.pathExtension.lowercased()
        let id = "orig\(originalIds.count).\(ext.isEmpty ? "jpg" : ext)"
        images[id] = data
        originalIds[key] = id
        return id
    }

    /// Loads a local image file, downsamples to `maxPixel` (longest edge), returns attachment id.
    @discardableResult
    func load(_ path: String, maxPixel: Int = 600) -> String? {
        guard let url = resolve(path) else { return nil }
        let key = url.standardizedFileURL.path
        if let id = idsBySource[key] { return id }

        guard FileManager.default.fileExists(atPath: key),
              let imageSource = CGImageSourceCreateWithURL(url as CFURL, nil)
        else { return nil }

        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
        ]
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary)
        else { return nil }

        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, UTType.jpeg.identifier as CFString, 1, nil)
        else { return nil }
        CGImageDestinationAddImage(dest, thumbnail, [kCGImageDestinationLossyCompressionQuality: 0.85] as CFDictionary)
        guard CGImageDestinationFinalize(dest) else { return nil }

        let jpeg = data as Data
        if let existing = idsByContent[jpeg] {
            idsBySource[key] = existing
            return existing
        }
        let id = "img\(images.count).jpg"
        images[id] = jpeg
        idsBySource[key] = id
        idsByContent[jpeg] = id
        return id
    }
}
