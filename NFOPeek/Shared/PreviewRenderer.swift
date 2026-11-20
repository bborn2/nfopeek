import Foundation
import UniformTypeIdentifiers

/// Generates an HTML preview from a movie.nfo file, returning a QLPreviewReply
/// (pair of HTML content + local image attachment dictionary).
enum PreviewRenderer {
    struct Preview {
        var html: String
        /// Maps `cid:filename` (the image ID) to the image data.
        var images: [String: Data] = [:]
    }

    /// Load the movie.nfo at the given URL plus any referenced local images.
    static func renderMoviePreview(nfoURL: URL) -> Preview? {
        guard let data = try? Data(contentsOf: nfoURL),
              let movie = NFOParser.parseMovie(data)
        else { return nil }

        let nfoDir = nfoURL.deletingLastPathComponent()
        var images: [String: Data] = [:]

        func loadImage(_ path: String) -> String? {
            let url = nfoDir.appendingPathComponent(path)
            guard let data = try? Data(contentsOf: url),
                  data.count > 0,
                  data.count < 20_000_000  // 20 MB sanity check
            else { return nil }
            let ext = url.pathExtension.isEmpty ? "jpg" : url.pathExtension.lowercased()
            let id = "img\(images.count).\(ext)"
            images[id] = data
            return id
        }

        let baseName = nfoURL.deletingPathExtension().lastPathComponent
        let posterCandidates = [movie.posterPath].compactMap { $0 }
            + ["jpg", "jpeg", "png", "webp"].flatMap { ext in
                ["poster.\(ext)", "\(baseName)-poster.\(ext)", "folder.\(ext)"]
            }
        var posterID: String?
        for candidate in posterCandidates {
            if let id = loadImage(candidate) { posterID = id; break }
        }
        let fanartIDs = movie.fanartPaths.compactMap(loadImage)

        let html = generateHTML(movie: movie, posterID: posterID, fanartIDs: fanartIDs)
        return Preview(html: html, images: images)
    }

    private static func generateHTML(movie: NFOMovie, posterID: String?, fanartIDs: [String]) -> String {
        var html = """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="UTF-8">
        <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background: #1a1a1a;
            color: #e0e0e0;
            padding: 24px;
            line-height: 1.6;
        }
        .container { max-width: 900px; margin: 0 auto; }
        .header {
            display: flex;
            gap: 24px;
            margin-bottom: 24px;
        }
        .poster {
            flex-shrink: 0;
            width: 280px;
            border-radius: 8px;
            overflow: hidden;
            background: #2a2a2a;
        }
        .poster img {
            width: 100%;
            height: auto;
            display: block;
        }
        .info { flex: 1; }
        .title {
            font-size: 28px;
            font-weight: 700;
            margin-bottom: 8px;
            color: #fff;
        }
        .meta {
            font-size: 14px;
            color: #aaa;
            margin-bottom: 16px;
        }
        .meta span { margin-right: 12px; }
        .meta span::before { content: "• "; margin-right: 4px; }
        .meta span:first-child::before { content: ""; margin: 0; }
        .genres {
            display: flex;
            flex-wrap: wrap;
            gap: 8px;
            margin-bottom: 16px;
        }
        .genre {
            background: #2a2a2a;
            padding: 4px 12px;
            border-radius: 4px;
            font-size: 13px;
        }
        .plot {
            margin: 16px 0;
            font-size: 15px;
            line-height: 1.7;
        }
        .people { margin-top: 16px; font-size: 14px; }
        .people dt {
            font-weight: 600;
            color: #bbb;
            display: inline;
            margin-right: 8px;
        }
        .people dd {
            display: inline;
            margin-bottom: 6px;
        }
        .people dd::after { content: "\\A"; white-space: pre; }
        .fanart {
            margin-top: 24px;
            display: grid;
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
            gap: 12px;
        }
        .fanart img {
            width: 100%;
            height: auto;
            border-radius: 6px;
            display: block;
        }
        @media (prefers-color-scheme: light) {
            body { background: #f5f5f5; color: #333; }
            .title { color: #000; }
            .meta { color: #666; }
            .genre { background: #e0e0e0; }
            .people dt { color: #555; }
            .poster { background: #ddd; }
        }
        </style>
        </head>
        <body>
        <div class="container">
        <div class="header">
        """

        if let posterID = posterID {
            html += #"<div class="poster"><img src="cid:\#(posterID)" alt="Poster"></div>"#
        }

        html += #"<div class="info">"#
        html += #"<h1 class="title">\#(escape(movie.title ?? "Unknown Title"))</h1>"#

        var metaParts: [String] = []
        if let year = movie.year { metaParts.append(escape(year)) }
        if let runtime = movie.runtimeMinutes { metaParts.append("\(escape(runtime)) min") }
        if let mpaa = movie.mpaa { metaParts.append(escape(mpaa)) }
        if let rating = movie.rating { metaParts.append("⭐️ \(escape(rating))") }
        if !metaParts.isEmpty {
            html += #"<div class="meta">"# + metaParts.map { "<span>\($0)</span>" }.joined() + "</div>"
        }

        if !movie.genres.isEmpty {
            html += #"<div class="genres">"#
                + movie.genres.map { #"<span class="genre">\#(escape($0))</span>"# }.joined()
                + "</div>"
        }

        if let plot = movie.plot {
            html += #"<div class="plot">\#(escape(plot))</div>"#
        }

        html += #"<dl class="people">"#
        if let director = movie.director {
            html += #"<dt>Director:</dt><dd>\#(escape(director))</dd>"#
        }
        if !movie.actors.isEmpty {
            html += #"<dt>Cast:</dt><dd>\#(escape(movie.actors.prefix(5).joined(separator: ", ")))</dd>"#
        }
        if let studio = movie.studio {
            html += #"<dt>Studio:</dt><dd>\#(escape(studio))</dd>"#
        }
        if let num = movie.number {
            html += #"<dt>Number:</dt><dd>\#(escape(num))</dd>"#
        }
        html += "</dl>"

        html += "</div></div>"  // close info and header

        if !fanartIDs.isEmpty {
            html += #"<div class="fanart">"#
                + fanartIDs.map { #"<img src="cid:\#($0)" alt="Fanart">"# }.joined()
                + "</div>"
        }

        html += """
        </div>
        </body>
        </html>
        """
        return html
    }

    private static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
