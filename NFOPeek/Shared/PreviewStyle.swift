enum PreviewStyle {
    static let css = """
    :root {
      --bg: #1a1a1a; --fg: #e0e0e0; --muted: #aaa; --card: #2a2a2a; --line: #333; --chip: #2a2a2a;
    }
    @media (prefers-color-scheme: light) {
      :root { --bg: #f5f5f5; --fg: #222; --muted: #666; --card: #fff; --line: #ddd; --chip: #e0e0e0; }
    }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font: 14px/1.6 -apple-system, "PingFang SC", sans-serif; background: var(--bg); color: var(--fg); padding: 24px; }

    .header { display: flex; gap: 24px; }
    .poster { flex-shrink: 0; width: 220px; border-radius: 8px; overflow: hidden; background: var(--card); }
    .poster img { width: 100%; display: block; }
    .info { flex: 1; min-width: 0; }
    .title { font-size: 26px; font-weight: 700; line-height: 1.25; }
    .original { color: var(--muted); font-size: 15px; margin-top: 2px; }
    .meta { margin-top: 10px; color: var(--muted); display: flex; flex-wrap: wrap; gap: 4px 12px; }
    .meta .rating { color: #f5c518; font-weight: 600; }
    .chips { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 12px; }
    .chip { background: var(--chip); padding: 3px 10px; border-radius: 4px; font-size: 12px; }
    .plot { margin-top: 14px; font-size: 14px; line-height: 1.7; white-space: pre-line; }
    dl.facts { margin-top: 14px; font-size: 13px; }
    dl.facts dt { font-weight: 600; color: var(--muted); display: inline; }
    dl.facts dd { display: inline; margin-left: 6px; }
    dl.facts dd::after { content: "\\A"; white-space: pre; }

    section { margin-top: 24px; }
    h2 { font-size: 13px; font-weight: 600; letter-spacing: .05em; text-transform: uppercase;
         color: var(--muted); margin-bottom: 10px; padding-bottom: 6px; border-bottom: 1px solid var(--line); }
    .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 12px; }
    .grid img { width: 100%; border-radius: 6px; display: block; }
    .card { background: var(--card); border-radius: 6px; overflow: hidden; }
    .card img { width: 100%; aspect-ratio: 2 / 3; object-fit: cover; display: block; }
    .card .caption { padding: 6px 8px; font-size: 12px; }
    .noimg { aspect-ratio: 2 / 3; display: flex; align-items: center; justify-content: center;
             font-size: 28px; color: var(--muted); background: var(--chip); }
    """
}
