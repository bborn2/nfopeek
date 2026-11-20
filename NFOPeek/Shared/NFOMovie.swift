import Foundation

/// Metadata parsed from an Emby/Kodi style movie.nfo file.
struct NFOMovie {
    struct Cast {
        var name: String
        var role: String?
    }

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
    var writers: [String] = []
    var plot: String?
    var genres: [String] = []
    var actors: [Cast] = []
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
        movie.studio = texts(root.elements(forName: "studio")).joined(separator: ", ").nilIfEmpty ?? text("maker")
        movie.director = texts(root.elements(forName: "director")).joined(separator: ", ").nilIfEmpty
        movie.writers = texts(root.elements(forName: "credits"))
        movie.plot = text("plot") ?? text("outline")

        let genres = texts(root.elements(forName: "genre"))
        movie.genres = genres.isEmpty ? texts(root.elements(forName: "tag")) : genres
        movie.actors = root.elements(forName: "actor").compactMap { actorEl -> NFOMovie.Cast? in
            guard let name = actorEl.elements(forName: "name").first?.stringValue?.nilIfEmpty else { return nil }
            let role = actorEl.elements(forName: "role").first?.stringValue?.nilIfEmpty
            return NFOMovie.Cast(name: name, role: role)
        }

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
        // Allow both local paths and remote URLs now that the extension has network access
        !path.isEmpty
    }
}

extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
