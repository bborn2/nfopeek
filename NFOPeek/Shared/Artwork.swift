import Foundation

/// Maps local image files to display slots: poster, seasons, gallery.
struct Artwork {
    struct Season: Identifiable { var id: Int { number }; let number: Int; let name: String; let poster: String? }

    var poster: String?
    var seasons: [Season] = []
    /// All other images: fanart, stills, artwork, etc. Each path appears once (byte-identical files deduplicated).
    var gallery: [String] = []

    private static let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "webp", "gif"]

    static func resolve(_ item: NFOItem, nfoURL: URL) -> Artwork {
        let dir = nfoURL.deletingLastPathComponent()
        let base = nfoURL.deletingPathExtension().lastPathComponent.lowercased()
        let files = ((try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? [])
            .filter { imageExtensions.contains(($0 as NSString).pathExtension.lowercased()) }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }

        func stem(_ file: String) -> String {
            var s = (file as NSString).deletingPathExtension.lowercased()
            for sep in ["-", "."] where s.hasPrefix(base + sep) { s = String(s.dropFirst(base.count + 1)) }
            return s
        }
        let byStem = Dictionary(files.map { (stem($0), $0) }, uniquingKeysWith: { a, _ in a })
        func path(_ file: String) -> String { dir.appendingPathComponent(file).path }
        func findLocal(_ stems: [String]) -> String? { stems.lazy.compactMap { byStem[$0] }.first.map(path) }

        var art = Artwork()
        var dedupe = Dedupe()

        // Poster: local file wins (poster.jpg, folder.jpg, cover.jpg, <base>-poster.jpg)
        art.poster = findLocal(["poster", "folder", "cover", base + "-poster"])
        art.poster.map { _ = dedupe.isNew($0) }

        // Seasons (TV shows only)
        let numbers = Set(item.seasonNames.keys).union(item.art.compactMap(\.season)).sorted()
        art.seasons = numbers.map { n in
            let stem = n == 0 ? "season-specials" : String(format: "season%02d", n)
            let poster = findLocal([stem + "-poster", stem])
            poster.map { _ = dedupe.isNew($0) }
            return Season(number: n, name: item.seasonNames[n] ?? (n == 0 ? "Specials" : "Season \(n)"), poster: poster)
        }

        // Gallery: everything else in the folder (fanart, backdrop, stills, artwork, ...)
        art.gallery = files.map(path).filter { dedupe.isNew($0) }
        return art
    }

    /// Drops repeated paths and byte-identical local files (e.g. poster.jpg == folder.jpg).
    private struct Dedupe {
        private var seen = Set<String>()
        private var bySize: [Int: [String]] = [:]

        mutating func isNew(_ source: String) -> Bool {
            guard seen.insert(source).inserted else { return false }
            guard let size = (try? FileManager.default.attributesOfItem(atPath: source))?[.size] as? Int
            else { return true }
            let twins = bySize[size, default: []]
            if !twins.isEmpty, let data = FileManager.default.contents(atPath: source),
               twins.contains(where: { FileManager.default.contents(atPath: $0) == data }) { return false }
            bySize[size, default: []].append(source)
            return true
        }
    }
}
