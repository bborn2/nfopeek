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

    .header { display: flex; gap: 24px; max-width: 1400px; }
    .poster { flex-shrink: 0; align-self: flex-start; width: 220px; }
    .poster img { width: 100%; display: block; border-radius: 8px; }
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

    /* Masonry grid: images keep their aspect ratio and pack tightly, laid out in reading order by JS below */
    .grid { position: relative; }
    .grid img { position: absolute; border-radius: 6px; display: block; cursor: pointer; transition: opacity .2s; }
    .grid img:hover { opacity: .85; }

    .card { background: var(--card); border-radius: 6px; overflow: hidden; }
    .card img { width: 100%; aspect-ratio: 2 / 3; object-fit: cover; display: block; cursor: pointer; }
    .card .caption { padding: 6px 8px; font-size: 12px; }
    .noimg { aspect-ratio: 2 / 3; display: flex; align-items: center; justify-content: center;
             font-size: 28px; color: var(--muted); background: var(--chip); }

    /* Lightbox overlay - fill more screen */
    #lightbox { display: none; position: fixed; inset: 0; background: rgba(0,0,0,.95); z-index: 9999;
                align-items: center; justify-content: center; cursor: zoom-out; }
    #lightbox.show { display: flex; }
    #lightbox img { max-width: 98vw; max-height: 98vh; border-radius: 4px; box-shadow: 0 20px 80px rgba(0,0,0,.7); }
    """

    static let js = """
    document.addEventListener('click', e => {
      if (e.target.tagName === 'IMG' && e.target.closest('.grid, .card')) {
        let lb = document.getElementById('lightbox');
        if (!lb) {
          lb = document.createElement('div');
          lb.id = 'lightbox';
          lb.innerHTML = '<img>';
          document.body.appendChild(lb);
          lb.addEventListener('click', () => lb.classList.remove('show'));
        }
        lb.querySelector('img').src = e.target.src;
        lb.classList.add('show');
      }
    });

    // Masonry: images pack tightly like a photo wall, using shortest-column-first
    // to balance column heights, rather than fixed reading order.
    function layoutMasonry(grid) {
      const gap = 12;
      const width = grid.clientWidth;
      const cols = width > 2200 ? 6 : width > 1600 ? 5 : width > 1200 ? 4 : width > 800 ? 3 : 2;
      const colWidth = (width - gap * (cols - 1)) / cols;
      const colHeights = new Array(cols).fill(0);
      const imgs = Array.from(grid.querySelectorAll('img'));
      let loaded = 0;

      function place(img) {
        const ratio = img.naturalHeight / img.naturalWidth || 1.5;
        const h = colWidth * ratio;
        const col = colHeights.indexOf(Math.min(...colHeights));
        img.style.width = colWidth + 'px';
        img.style.height = h + 'px';
        img.style.left = col * (colWidth + gap) + 'px';
        img.style.top = colHeights[col] + 'px';
        colHeights[col] += h + gap;
      }

      imgs.forEach((img) => {
        if (img.complete && img.naturalWidth) {
          place(img);
          loaded++;
          if (loaded === imgs.length) grid.style.height = Math.max(...colHeights) + 'px';
        } else {
          img.addEventListener('load', () => {
            place(img);
            loaded++;
            grid.style.height = Math.max(...colHeights) + 'px';
          });
        }
      });
      if (imgs.length) grid.style.height = Math.max(...colHeights, 100) + 'px';
    }

    document.querySelectorAll('.grid').forEach(layoutMasonry);
    let resizeTimer;
    window.addEventListener('resize', () => {
      clearTimeout(resizeTimer);
      resizeTimer = setTimeout(() => document.querySelectorAll('.grid').forEach(layoutMasonry), 100);
    });
    """
}
