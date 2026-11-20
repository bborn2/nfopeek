import Foundation

/// Decides which image fills which slot. For every slot a local file wins; a URL from the
/// nfo is only fetched when nothing local exists. Every other image in the folder is kept too.
struct Artwork {
    struct Season { var number: Int; var name: String; var poster: String? }
    struct Extra { var label: String; var id: String }

    var poster: String?
    var backdrop: String?
    var logo: String?
    var seasons: [Season] = []
    var stills: [String] = []
    /// Remaining artwork (banner, clearart, disc, keyart...), labelled for the gallery.
    var extras: [Extra] = []
    /// Headshot attachment id per actor index.
    var headshots: [Int: String] = [:]

    static let slotNames: [String: [String]] = [
        "poster": ["poster", "folder", "cover", "movie-poster"],
        "fanart": ["fanart", "backdrop", "background"],
        "clearlogo": ["clearlogo", "logo"],
        "banner": ["banner"], "clearart": ["clearart"], "keyart": ["keyart"],
        "landscape": ["landscape", "thumb"], "discart": ["disc", "discart"],
        "characterart": ["characterart"],
    ]
    static let extraOrder = ["banner", "landscape", "keyart", "clearart", "characterart", "discart"]
    static let imageExtensions: Set<String> = ["jpg", "jpeg", "png", "webp", "gif"]

    static func resolve(_ item: NFOItem, nfoURL: URL, store: ImageStore, maxHeadshots: Int = 30) -> Artwork {
        let dir = nfoURL.deletingLastPathComponent()
        let base = nfoURL.deletingPathExtension().lastPathComponent.lowercased()
        let files = ((try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? [])
            .filter { imageExtensions.contains(($0 as NSString).pathExtension.lowercased()) }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
        // "poster", "<base>-poster" and "<base>.poster" all map to "poster".
        func stem(_ file: String) -> String {
            var s = (file as NSString).deletingPathExtension.lowercased()
            for sep in ["-", "."] where s.hasPrefix(base + sep) { s = String(s.dropFirst(base.count + 1)) }
            return s
        }
        let byStem = Dictionary(files.map { (stem($0), $0) }, uniquingKeysWith: { first, _ in first })
        func localFile(_ names: [String]) -> String? { names.lazy.compactMap { byStem[$0] }.first }
        func seasonStem(_ n: Int) -> String { n == 0 ? "season-specials" : String(format: "season%02d", n) }

        // 1. Work out the source for each slot, then fetch every needed URL in one parallel batch.
        var slot: [String: String] = [:]
        for (aspect, names) in slotNames {
            let nfoArt = aspect == "fanart" ? [] : item.art(aspect) + (aspect == "landscape" ? item.art("thumb") : [])
            if let source = localFile(names) ?? nfoArt.first(where: { !ImageStore.isRemote($0) }) ?? nfoArt.first {
                slot[aspect] = source
            }
        }
        let localStills = item.fanart.filter { !ImageStore.isRemote($0) }
        if slot["fanart"] == nil {
            // A single <fanart><thumb> is the backdrop; a long list (JAV scrapers) is a set of stills.
            slot["fanart"] = localStills.count > 1 ? nil : (localStills.first ?? item.fanart.first)
        }
        let seasonNumbers = Set(item.seasonNames.keys).union(item.art.compactMap(\.season)).sorted()
        var seasonPoster: [Int: String] = [:]
        for n in seasonNumbers {
            seasonPoster[n] = localFile([seasonStem(n) + "-poster"]) ?? item.art("poster", season: n).first
        }
        let actors = Array(item.actors.prefix(maxHeadshots).enumerated()).compactMap { i, p in
            p.thumb.map { (i, ImageStore.isRemote($0) ? smallTMDB($0) : $0) }
        }
        store.fetch(Array(slot.values) + Array(seasonPoster.values) + actors.map(\.1))

        // 2. Map sources to attachment ids.
        var art = Artwork()
        art.poster = slot["poster"].flatMap(store.id(for:))
        art.backdrop = slot["fanart"].flatMap(store.id(for:))
        art.logo = slot["clearlogo"].flatMap(store.id(for:))
        for (i, source) in actors { art.headshots[i] = store.id(for: source) }
        art.seasons = seasonNumbers.map { n in
            Season(number: n, name: item.seasonNames[n] ?? (n == 0 ? "Specials" : "Season \(n)"),
                   poster: seasonPoster[n].flatMap(store.id(for:)))
        }
        var used = Set([art.poster, art.backdrop, art.logo].compactMap { $0 } + art.seasons.compactMap(\.poster))
        art.stills = (localStills + files.filter { stem($0).hasPrefix("extrafanart") })
            .compactMap(store.local).filter { used.insert($0).inserted }
        for aspect in extraOrder {
            if let id = slot[aspect].flatMap(store.id(for:)), used.insert(id).inserted {
                art.extras.append(Extra(label: aspect, id: id))
            }
        }
        // 3. Anything else in the folder (season banners, unknown names) goes to the gallery.
        for file in files {
            if let id = store.local(file), used.insert(id).inserted {
                art.extras.append(Extra(label: stem(file), id: id))
            }
        }
        return art
    }

    /// TMDB serves any size from the same path; headshots only need w185.
    static func smallTMDB(_ url: String) -> String {
        guard url.contains("image.tmdb.org/t/p/") else { return url }
        return url.replacingOccurrences(of: #"/t/p/[^/]+/"#, with: "/t/p/w185/", options: .regularExpression)
    }
}
