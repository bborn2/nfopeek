import Foundation

/// Metadata parsed from an Emby/Kodi style movie.nfo file.
struct NFOMovie {
    var title: String?
    var originalTitle: String?
    var number: String?
    var year: String?
    var releaseDate: String?
    var runtimeMinutes: String?
    var mpaa: String?
    var rating: String?
    var studio: String?
    var director: String?
    var plot: String?
    var genres: [String] = []
    var actors: [String] = []
    /// Image paths referenced by the nfo, relative to the nfo's directory or absolute.
    /// Remote URLs are dropped because the preview has no network access.
    var posterPath: String?
    var fanartPaths: [String] = []
}

enum NFOParser {
    /// Returns nil when the data is not an XML document with a <movie> root,
    /// e.g. a plain-text scene release .nfo.
    static func parseMovie(_ data: Data) -> NFOMovie? {
        guard let doc = try? XMLDocument(data: data, options: [.nodeLoadExternalEntitiesNever]),
              let root = doc.rootElement(),
              root.name?.lowercased() == "movie"
        else { return nil }

        func text(_ name: String) -> String? {
            let value = root.elements(forName: name).first?.stringValue?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return (value?.isEmpty ?? true) ? nil : value
        }
        func texts(_ elements: [XMLElement]) -> [String] {
            var seen = Set<String>()
            return elements
                .compactMap { $0.stringValue?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && seen.insert($0).inserted }
        }

        var movie = NFOMovie()
        movie.title = text("title")
        movie.originalTitle = text("originaltitle")
        movie.number = text("num") ?? text("sorttitle")
        movie.year = text("year")
        movie.releaseDate = text("premiered") ?? text("release") ?? text("releasedate")
        movie.runtimeMinutes = text("runtime")
        movie.mpaa = text("mpaa")
        movie.rating = text("rating") ?? ratingFromRatingsBlock(root)
        movie.studio = text("studio") ?? text("maker")
        movie.director = texts(root.elements(forName: "director")).joined(separator: ", ").nilIfEmpty
        movie.plot = text("plot") ?? text("outline")

        let genres = texts(root.elements(forName: "genre"))
        movie.genres = genres.isEmpty ? texts(root.elements(forName: "tag")) : genres
        movie.actors = texts(root.elements(forName: "actor").flatMap { $0.elements(forName: "name") })

        // Kodi may declare the poster as a top-level <thumb aspect="poster">.
        // When absent, the renderer falls back to conventional file names (poster.jpg ...).
        let topThumbs = root.elements(forName: "thumb")
        let posterThumb = topThumbs.first { $0.attribute(forName: "aspect")?.stringValue == "poster" }
            ?? topThumbs.first
        if let poster = posterThumb?.stringValue?.nilIfEmpty, isLocalPath(poster) {
            movie.posterPath = poster
        }
        // Every <fanart><thumb> is a still for the gallery.
        movie.fanartPaths = texts(root.elements(forName: "fanart").flatMap { $0.elements(forName: "thumb") })
            .filter(isLocalPath)
        return movie
    }

    /// Newer Kodi format: <ratings><rating default="true"><value>7.5</value></rating></ratings>
    private static func ratingFromRatingsBlock(_ root: XMLElement) -> String? {
        let ratings = root.elements(forName: "ratings").flatMap { $0.elements(forName: "rating") }
        let chosen = ratings.first { $0.attribute(forName: "default")?.stringValue == "true" } ?? ratings.first
        return chosen?.elements(forName: "value").first?.stringValue?.nilIfEmpty
    }

    private static func isLocalPath(_ path: String) -> Bool {
        !path.isEmpty && !path.contains("://")
    }
}

extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
