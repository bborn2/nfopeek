struct HTMLRenderer {
    let item: NFOItem
    let art: Artwork
    let store: ImageStore

    func render() -> String {
        """
        <!DOCTYPE html><html><head><meta charset="UTF-8">
        <style>\(PreviewStyle.css)</style></head><body>
        \(header())\(main())</body></html>
        """
    }

    private func header() -> String {
        var s = "<div class=\"header\">"
        if let poster = art.poster, let id = store.load(poster) {
            s += "<div class=\"poster\"><img src=\"cid:\(id)\" alt=\"Poster\"></div>"
        }
        s += "<div class=\"info\">"
        s += "<h1 class=\"title\">\(esc(item.title ?? "Untitled"))</h1>"
        if let orig = item.originalTitle, orig != item.title { s += "<div class=\"original\">\(esc(orig))</div>" }
        s += metadata()
        s += chips(item.genres)
        if let plot = item.plot { s += "<div class=\"plot\">\(esc(plot))</div>" }
        s += facts()
        s += "</div></div>"
        return s
    }

    private func metadata() -> String {
        var parts: [String] = []
        if let year = item.year { parts.append(year) }
        if item.kind == .tvshow, let status = item.status { parts.append(status) }
        if item.kind == .episode, let s = item.season, let e = item.episode {
            parts.append("S\(String(format: "%02d", s))E\(String(format: "%02d", e))")
        }
        if let runtime = item.runtime { parts.append("\(runtime) min") }
        if let mpaa = item.mpaa { parts.append(mpaa) }
        if let r = item.rating {
            let v = item.votes.map { " (\($0))" } ?? ""
            parts.append("<span class=\"rating\">★ \(r)\(v)</span>")
        }
        return parts.isEmpty ? "" : "<div class=\"meta\">\(parts.joined(separator: " · "))</div>"
    }

    private func chips(_ labels: [String]) -> String {
        guard !labels.isEmpty else { return "" }
        return "<div class=\"chips\">\(labels.map { "<span class=\"chip\">\(esc($0))</span>" }.joined())</div>"
    }

    private func facts() -> String {
        var rows: [(String, String)] = []
        if !item.directors.isEmpty { rows.append(("Director", item.directors.joined(separator: ", "))) }
        if !item.writers.isEmpty { rows.append(("Writer", item.writers.joined(separator: ", "))) }
        if !item.actors.isEmpty {
            rows.append(("Cast", item.actors.prefix(6).map(\.name).joined(separator: ", ")))
        }
        if !item.studios.isEmpty { rows.append(("Studio", item.studios.joined(separator: ", "))) }
        if let aired = item.premiered { rows.append(("Aired", aired)) }
        if let num = item.number { rows.append(("Number", num)) }
        guard !rows.isEmpty else { return "" }
        return "<dl class=\"facts\">" + rows.map { "<dt>\($0.0)</dt><dd>\(esc($0.1))</dd>" }.joined() + "</dl>"
    }

    private func main() -> String {
        var s = "<main>"
        if !art.seasons.isEmpty { s += section("Seasons", grid: seasons()) }
        if !art.gallery.isEmpty { s += section("Gallery", grid: gallery()) }
        return s + "</main>"
    }

    private func section(_ title: String, grid: String) -> String {
        "<section><h2>\(title)</h2><div class=\"grid\">\(grid)</div></section>"
    }

    private func seasons() -> String {
        art.seasons.map { s in
            if let poster = s.poster, let id = store.load(poster, maxPixel: 400) {
                return "<div class=\"card\"><img src=\"cid:\(id)\"><div class=\"caption\">\(esc(s.name))</div></div>"
            } else {
                return "<div class=\"card\"><div class=\"noimg\">\(s.number)</div><div class=\"caption\">\(esc(s.name))</div></div>"
            }
        }.joined()
    }

    private func gallery() -> String {
        art.gallery.compactMap { path in
            store.load(path).map { "<img src=\"cid:\($0)\">" }
        }.joined()
    }

    private func esc(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
