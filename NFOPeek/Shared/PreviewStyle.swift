enum PreviewStyle {
    static let css = """
    :root {
      --bg: #141414; --fg: #e8e8e8; --muted: #9a9a9a; --card: #222; --line: #2e2e2e;
      --chip: rgba(255,255,255,.1); --shade: 20,20,20;
    }
    @media (prefers-color-scheme: light) {
      :root { --bg: #f4f4f4; --fg: #1d1d1f; --muted: #6e6e73; --card: #fff; --line: #ddd;
              --chip: rgba(0,0,0,.07); --shade: 244,244,244; }
    }
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font: 14px/1.55 -apple-system, "PingFang SC", sans-serif; background: var(--bg); color: var(--fg); }

    .hero { position: relative; padding: 28px 32px 24px; display: flex; gap: 28px; align-items: flex-end;
            min-height: 46vh; background-size: cover; background-position: center 20%; }
    .hero.has-backdrop::before { content: ""; position: absolute; inset: 0;
      background: linear-gradient(to top, rgb(var(--shade)) 0%, rgba(var(--shade),.86) 40%, rgba(var(--shade),.25) 100%); }
    .hero > * { position: relative; }
    .poster { width: clamp(150px, 22vw, 260px); flex-shrink: 0; border-radius: 10px;
              box-shadow: 0 10px 30px rgba(0,0,0,.45); }
    .headline { flex: 1; min-width: 0; }
    .logo { max-width: min(420px, 70%); max-height: 120px; display: block; margin-bottom: 10px; }
    h1 { font-size: 30px; line-height: 1.2; font-weight: 700; }
    .logo + h1 { font-size: 20px; }
    .original { color: var(--muted); font-size: 16px; margin-top: 2px; }
    .tagline { font-style: italic; color: var(--muted); margin-top: 6px; }
    .meta { margin-top: 10px; color: var(--muted); display: flex; flex-wrap: wrap; gap: 4px 14px; }
    .meta .rating { color: #f5c518; font-weight: 600; }
    .chips { display: flex; flex-wrap: wrap; gap: 6px; margin-top: 12px; }
    .chip { background: var(--chip); padding: 2px 10px; border-radius: 99px; font-size: 12px; }
    .chip.tag { opacity: .7; }

    main { padding: 4px 32px 32px; }
    .overview { display: grid; grid-template-columns: minmax(0, 2fr) minmax(220px, 1fr); gap: 32px; }
    @media (max-width: 760px) { .overview { grid-template-columns: 1fr; } .hero { flex-direction: column; align-items: flex-start; } }
    .plot { font-size: 15px; line-height: 1.75; white-space: pre-line; }
    dl.facts { display: grid; grid-template-columns: auto 1fr; gap: 6px 14px; font-size: 13px; align-content: start; }
    dl.facts dt { color: var(--muted); white-space: nowrap; }

    section { margin-top: 28px; }
    h2 { font-size: 13px; font-weight: 600; letter-spacing: .06em; text-transform: uppercase;
         color: var(--muted); margin-bottom: 12px; padding-bottom: 6px; border-bottom: 1px solid var(--line); }
    .grid { display: grid; gap: 14px; }
    .cast { grid-template-columns: repeat(auto-fill, minmax(104px, 1fr)); }
    .seasons { grid-template-columns: repeat(auto-fill, minmax(130px, 1fr)); }
    .stills { grid-template-columns: repeat(auto-fill, minmax(260px, 1fr)); }
    .extras { grid-template-columns: repeat(auto-fill, minmax(220px, 1fr)); }
    .card { background: var(--card); border-radius: 8px; overflow: hidden; }
    .card img { width: 100%; display: block; }
    .card .caption { padding: 6px 8px 8px; font-size: 12px; line-height: 1.35; }
    .card .sub { color: var(--muted); }
    .cast .card img, .cast .card .noimg { aspect-ratio: 2 / 3; object-fit: cover; }
    .seasons .card img, .seasons .card .noimg { aspect-ratio: 2 / 3; object-fit: cover; }
    .noimg { display: flex; align-items: center; justify-content: center; font-size: 32px;
             color: var(--muted); background: var(--chip); }
    .stills img { border-radius: 6px; width: 100%; aspect-ratio: 16 / 9; object-fit: cover; display: block; }
    .extras .card img { height: 150px; object-fit: contain; padding: 8px;
      background: repeating-conic-gradient(var(--chip) 0 25%, transparent 0 50%) 0 0 / 16px 16px; }
    """
}
