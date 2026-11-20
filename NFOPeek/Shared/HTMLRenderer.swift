struct HTMLRenderer {
    static let maxCast = 30
    let item: NFOItem
    let art: Artwork
    let store: ImageStore

    func render() -> String {
        """
        <!DOCTYPE html><html><head><meta charset="UTF-8">
        <style>\(PreviewStyle.css)</style></head><body>
        \(hero())\(main())</body></html>
        """
    }

    private func hero() -> String {
        var s = ""
        let cls = art.backdrop != nil ? "hero has-backdrop" : "hero"
        s += "<div class=\"\(cls)\">"
        if let backdropID = art.backdrop {
            s += "<img src=\"cid:\(backdropID)\" style=\"position:absolute;inset:0;width:100%;height:100%;object-fit:cover;\">"
        }
        if let posterID = art.poster { s += "<img src=\"cid:\(posterID)\" class=\"poster\" alt=\"Poster\">" }
        s += "<div class=\"headline\">"
        if let logoID = art.logo { s += "<img src=\"cid:\(logoID)\" class=\"logo\" alt=\"Logo\">" }
        s += "<h1>\(esc(item.title ?? "Untitled"))</h1>"
        if let orig = item.originalTitle, orig != item.title { s += "<div class=\"original\">\(esc(orig))</div>" }
        if let tag = item.tagline { s += "<div class=\"tagline\">\(esc(tag))</div>" }
        s += metadata()
        s += chips(item.genres)
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

    private func main() -> String {
        var s = "<main><div class=\"overview\"><div>"
        if let plot = item.plot { s += "<div class=\"plot\">\(esc(plot))</div>" }
        s += "</div><div>\(facts())\(tags())</div></div>"
        if !item.actors.isEmpty { s += section("Cast", grid: cast()) }
        if !art.seasons.isEmpty { s += section("Seasons", grid: seasons()) }
        if !art.stills.isEmpty { s += section("Stills", grid: stills()) }
        if !art.extras.isEmpty { s += section("Artwork", grid: extras()) }
        return s + "</main>"
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

    private func tags() -> String { item.tags.isEmpty ? "" : "<div style=\"margin-top:14px\">\(chips(item.tags))</div>" }

    private func section(_ title: String, grid: String) -> String {
        "<section><h2>\(title)</h2><div class=\"grid \(title.lowercased())\">\(grid)</div></section>"
    }

    private func cast() -> String {
        item.actors.prefix(Self.maxCast).enumerated().map { i, p in
            let img = art.headshots[i].map { "<img src=\"cid:\($0)\">" }
                ?? "<div class=\"noimg\">\(p.name.prefix(1))</div>"
            let sub = p.role.map { "<div class=\"sub\">\(esc($0))</div>" } ?? ""
            return "<div class=\"card\">\(img)<div class=\"caption\">\(esc(p.name))\(sub)</div></div>"
        }.joined()
    }

    private func seasons() -> String {
        art.seasons.map { s in
            let img = s.poster.map { "<img src=\"cid:\($0)\">" } ?? "<div class=\"noimg\">\(s.number)</div>"
            return "<div class=\"card\">\(img)<div class=\"caption\">\(esc(s.name))</div></div>"
        }.joined()
    }

    private func stills() -> String { art.stills.map { "<img src=\"cid:\($0)\">" }.joined() }

    private func extras() -> String {
        art.extras.map { e in
            "<div class=\"card\"><img src=\"cid:\(e.id)\"><div class=\"caption\">\(esc(e.label))</div></div>"
        }.joined()
    }

    private func esc(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
