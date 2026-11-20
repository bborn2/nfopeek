import Foundation

enum NFOParser {
    /// Returns nil for anything that is not an XML movie/tvshow/episodedetails document,
    /// such as plain-text scene release .nfo files.
    static func parse(_ data: Data) -> NFOItem? {
        guard let doc = try? XMLDocument(data: data, options: [.nodeLoadExternalEntitiesNever]),
              let root = doc.rootElement()
        else { return nil }

        var item = NFOItem()
        switch root.name?.lowercased() {
        case "movie": item.kind = .movie
        case "tvshow": item.kind = .tvshow
        case "episodedetails": item.kind = .episode
        default: return nil
        }

        func values(_ name: String, in element: XMLElement = root) -> [String] {
            var seen = Set<String>()
            return element.elements(forName: name)
                .compactMap { $0.stringValue?.trimmed }
                .filter { !$0.isEmpty && seen.insert($0).inserted }
        }
        func value(_ name: String) -> String? { values(name).first }

        item.title = value("title")
        item.originalTitle = value("originaltitle")
        item.showTitle = value("showtitle")
        item.tagline = value("tagline")
        item.number = value("num")
        item.year = value("year")
        item.premiered = value("premiered") ?? value("aired") ?? value("release") ?? value("releasedate")
        item.runtime = value("runtime")
        item.mpaa = value("mpaa")
        item.status = value("status")
        item.season = value("season").flatMap { Int($0) }
        item.episode = value("episode").flatMap { Int($0) }
        item.plot = value("plot") ?? value("outline")
        item.genres = values("genre")
        item.tags = values("tag").filter { !item.genres.contains($0) }
        item.countries = values("country")
        item.studios = values("studio")
        if item.studios.isEmpty { item.studios = values("maker") }
        item.directors = values("director")
        item.writers = values("credits")
        (item.rating, item.votes) = rating(in: root, fallback: value("rating"))

        item.actors = root.elements(forName: "actor").compactMap { el -> NFOItem.Person? in
            guard let name = el.elements(forName: "name").first?.stringValue?.trimmed.nonEmpty
            else { return nil }
            return NFOItem.Person(
                name: name,
                role: el.elements(forName: "role").first?.stringValue?.trimmed.nonEmpty,
                thumb: el.elements(forName: "thumb").first?.stringValue?.trimmed.nonEmpty)
        }

        for el in root.elements(forName: "namedseason") {
            if let number = el.attribute(forName: "number")?.stringValue.flatMap({ Int($0) }),
               let name = el.stringValue?.trimmed.nonEmpty {
                item.seasonNames[number] = name
            }
        }

        // An episode's bare <thumb> is its still; elsewhere a bare <thumb> is the poster.
        let defaultAspect = item.kind == .episode ? "thumb" : "poster"
        item.art = root.elements(forName: "thumb").compactMap { el -> NFOItem.Art? in
            guard let source = el.stringValue?.trimmed.nonEmpty else { return nil }
            let aspect = el.attribute(forName: "aspect")?.stringValue?.lowercased().nonEmpty ?? defaultAspect
            let season = el.attribute(forName: "season")?.stringValue.flatMap { Int($0) }
            return NFOItem.Art(aspect: aspect, season: season, source: source)
        }
        item.fanart = root.elements(forName: "fanart").flatMap { values("thumb", in: $0) }
        return item
    }

    /// Kodi 17+: <ratings><rating default="true"><value>8.3</value><votes>8229</votes></rating></ratings>.
    /// Older files use a plain <rating>.
    private static func rating(in root: XMLElement, fallback: String?) -> (String?, String?) {
        let all = root.elements(forName: "ratings").flatMap { $0.elements(forName: "rating") }
        guard let chosen = all.first(where: { $0.attribute(forName: "default")?.stringValue == "true" }) ?? all.first
        else { return (fallback, nil) }
        let value = chosen.elements(forName: "value").first?.stringValue?.trimmed.nonEmpty
        let votes = chosen.elements(forName: "votes").first?.stringValue?.trimmed.nonEmpty
        return (value ?? fallback, votes)
    }
}
