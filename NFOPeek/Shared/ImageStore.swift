import Foundation

/// Collects the images attached to a Quick Look reply. The HTML references each one as `cid:<id>`.
final class ImageStore {
    private(set) var images: [String: Data] = [:]
    private var idsBySource: [String: String] = [:]
    private var idsByContent: [Data: String] = [:]
    private let baseDir: URL

    init(baseDir: URL) { self.baseDir = baseDir }

    static func isRemote(_ source: String) -> Bool { source.contains("://") }

    /// Attachment id for a local path or an already fetched URL.
    func id(for source: String) -> String? {
        Self.isRemote(source) ? idsBySource[source] : local(source)
    }

    /// Loads a file relative to the nfo directory (or an absolute path).
    @discardableResult
    func local(_ path: String) -> String? {
        guard !Self.isRemote(path) else { return nil }
        let url = path.hasPrefix("/") ? URL(fileURLWithPath: path) : baseDir.appendingPathComponent(path)
        let key = url.standardizedFileURL.path
        if let id = idsBySource[key] { return id }
        guard FileManager.default.fileExists(atPath: key),
              let data = try? Data(contentsOf: url, options: .mappedIfSafe)
        else { return nil }
        return add(data, key: key)
    }

    /// Downloads URLs in parallel and waits at most `timeout` seconds in total.
    /// Responses are cached on disk, so a second preview of the same file is instant.
    func fetch(_ sources: [String], timeout: TimeInterval = 6) {
        var seen = Set<String>()
        let pending = sources.filter { Self.isRemote($0) && idsBySource[$0] == nil && seen.insert($0).inserted }
        guard !pending.isEmpty else { return }

        let results = Results()
        let group = DispatchGroup()
        for source in pending {
            guard let url = Self.secureURL(source) else { continue }
            group.enter()
            Self.session.dataTask(with: url) { data, response, _ in
                defer { group.leave() }
                guard let data, (response as? HTTPURLResponse)?.statusCode == 200 else { return }
                results.set(source, data)
            }.resume()
        }
        _ = group.wait(timeout: .now() + timeout)
        // Insert in request order so attachment ids are stable.
        for source in pending {
            if let data = results.get(source) { add(data, key: source) }
        }
    }

    @discardableResult
    private func add(_ data: Data, key: String) -> String? {
        guard data.count < 40_000_000, let ext = Self.imageExtension(of: data) else { return nil }
        if let existing = idsByContent[data] {
            idsBySource[key] = existing
            return existing
        }
        let id = "img\(images.count).\(ext)"
        images[id] = data
        idsBySource[key] = id
        idsByContent[data] = id
        return id
    }

    /// Detects the format from magic bytes; file extensions in media folders are unreliable.
    private static func imageExtension(of data: Data) -> String? {
        let b = [UInt8](data.prefix(12))
        if b.starts(with: [0xFF, 0xD8, 0xFF]) { return "jpg" }
        if b.starts(with: [0x89, 0x50, 0x4E, 0x47]) { return "png" }
        if b.starts(with: [0x47, 0x49, 0x46]) { return "gif" }
        if b.count == 12, b[0..<4].elementsEqual([0x52, 0x49, 0x46, 0x46]),
           b[8..<12].elementsEqual([0x57, 0x45, 0x42, 0x50]) { return "webp" }
        return nil
    }

    /// App Transport Security blocks plain http; TMDB and fanart.tv both serve https.
    private static func secureURL(_ source: String) -> URL? {
        URL(string: source.hasPrefix("http://") ? "https://" + source.dropFirst(7) : source)
    }

    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 6
        config.requestCachePolicy = .returnCacheDataElseLoad
        config.urlCache = URLCache(memoryCapacity: 32 << 20, diskCapacity: 512 << 20)
        config.httpMaximumConnectionsPerHost = 6
        return URLSession(configuration: config)
    }()

    private final class Results: @unchecked Sendable {
        private var storage: [String: Data] = [:]
        private let lock = NSLock()
        func set(_ key: String, _ data: Data) { lock.lock(); storage[key] = data; lock.unlock() }
        func get(_ key: String) -> Data? { lock.lock(); defer { lock.unlock() }; return storage[key] }
    }
}
