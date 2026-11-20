import Foundation

/// Metadata from a Kodi/Emby nfo: movie, tvshow or episodedetails.
struct NFOItem {
    enum Kind { case movie, tvshow, episode }

    struct Person {
        var name: String
        var role: String?
        /// Headshot path or URL from <actor><thumb>.
        var thumb: String?
    }

    /// A top-level <thumb>, e.g. <thumb aspect="poster" season="1" type="season">.
    struct Art {
        var aspect: String
        var season: Int?
        /// Relative path, absolute path or URL.
        var source: String
    }

    var kind: Kind = .movie
    var title: String?
    var originalTitle: String?
    var showTitle: String?
    var tagline: String?
    /// Catalog number written by JAV scrapers (<num>).
    var number: String?
    var year: String?
    var premiered: String?
    var runtime: String?
    var mpaa: String?
    var rating: String?
    var votes: String?
    var status: String?
    var season: Int?
    var episode: Int?
    var plot: String?
    var genres: [String] = []
    var tags: [String] = []
    var countries: [String] = []
    var studios: [String] = []
    var directors: [String] = []
    var writers: [String] = []
    var actors: [Person] = []
    var seasonNames: [Int: String] = [:]
    var art: [Art] = []
    /// <fanart><thumb> entries: a backdrop (tinyMediaManager) or a list of stills (JAV scrapers).
    var fanart: [String] = []

    func art(_ aspect: String, season: Int? = nil) -> [String] {
        art.filter { $0.aspect == aspect && $0.season == season }.map(\.source)
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var nonEmpty: String? { isEmpty ? nil : self }
}
