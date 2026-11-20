# NFOPeek

macOS Quick Look extension for Kodi/Emby/Jellyfin `.nfo` metadata files.

Press **Space** in Finder to preview movie, TV show, and episode `.nfo` files with posters, metadata, and image galleries — no need to open a media player.

## Features

- 🎬 **Movie, TV show, and episode support** — parses `<movie>`, `<tvshow>`, and `<episodedetails>` formats
- 🖼️ **Local image gallery** — auto-loads posters, fanart, season posters, and artwork from the same directory
- 🧱 **Masonry photo wall** — responsive multi-column layout (2-6 columns) with horizontal reading order
- 🔍 **Click to zoom** — click any image for fullscreen preview
- 🌓 **Dark/light mode** — adapts to system appearance
- ⚡ **Fast loading** — downsamples images to 600px on the fly via ImageIO (no raw 2MB+ files)
- 📄 **Clean layout** — left-aligned poster, metadata sidebar, and scrollable gallery

## Requirements

- macOS 13.0+
- Xcode 15.0+ (for building)

## Build & Install

```bash
# Build Release configuration
xcodebuild -project NFOPeek.xcodeproj -scheme NFOPeek -configuration Release \
  -derivedDataPath build build

# Copy to ~/Applications (or /Applications)
cp -R build/Build/Products/Release/NFOPeek.app ~/Applications/

# Open once to register the extension
open ~/Applications/NFOPeek.app

# Verify extension is registered
pluginkit -m -p com.apple.quicklook.preview | grep NFOPeek

# Reset Quick Look cache to pick up the extension
qlmanage -r cache && qlmanage -r
```

After installation, select any `.nfo` file in Finder and press **Space** to preview.

## Usage

1. Launch `NFOPeek.app` once to register the Quick Look extension with macOS
2. Find a `.nfo` file (e.g., `movie.nfo`, `tvshow.nfo`, `<filename>.nfo`) in Finder
3. Press **Space** to open Quick Look preview
4. Click any image in the gallery to view it fullscreen; click again to close

## Project Structure

```
NFOPeek/
├── App/                      # Host macOS app (required for extension delivery)
│   ├── NFOPeekApp.swift
│   ├── ContentView.swift
│   └── Info.plist
├── Extension/                # Quick Look extension target
│   ├── PreviewProvider.swift  # Entry point: renders HTML + attachments
│   └── Info.plist
└── Shared/                   # Parsing & rendering logic
    ├── NFOItem.swift         # Data model for movie/tvshow/episode
    ├── NFOParser.swift       # XML parser (SAX-style)
    ├── Artwork.swift         # Image path resolver (poster, seasons, gallery)
    ├── ImageStore.swift      # Downsample & deduplicate local images
    ├── HTMLRenderer.swift    # Generate preview HTML
    └── PreviewStyle.swift    # CSS + JS (masonry layout, lightbox)
```

## Technical Details

- **UTI**: Declares `org.kodi.nfo` as exported type for `.nfo` files
- **Sandbox**: Uses temporary exception for read-only file access to load sibling images in the directory
- **Rendering**: Returns HTML with inline CSS/JS + image attachments via `QLPreviewReply`
- **Image pipeline**:
  1. `Artwork.resolve()` scans the `.nfo` directory for images (poster.jpg, fanart.jpg, seasonXX-poster.jpg, etc.)
  2. `ImageStore.load()` uses `CGImageSourceCreateThumbnailAtIndex` to downsample to 600px max edge
  3. Encodes as JPEG (quality 0.85) and attaches via `cid:` reference in HTML
  4. Content-based deduplication prevents identical files (e.g., `poster.jpg` = `folder.jpg`) from being attached twice
- **Layout**: JavaScript masonry distributes images across responsive columns (left-to-right reading order), preserving aspect ratios
- **Lightbox**: Click event listener shows fullscreen overlay with `position: fixed` and 98vw/98vh scaling

## Supported NFO Tags

### Movie (`<movie>`)
- Title, original title, year, runtime, MPAA rating, rating, votes
- Plot, tagline, genres, tags, studios, countries
- Director, writers, actors (with roles)
- Poster, fanart, all Kodi art types (banner, clearlogo, landscape, keyart, etc.)
- Catalog number (`<num>` for JAV scrapers)

### TV Show (`<tvshow>`)
- Title, year, premiered date, status (Continuing/Ended), runtime
- Plot, genres, tags, studios, directors, actors
- Season metadata (`<namedseason>` with season numbers and names)
- Poster, fanart, season posters (`season01-poster.jpg`, etc.)

### Episode (`<episodedetails>`)
- Title, show title, season/episode numbers, aired date
- Plot, directors, writers, actors
- Fanart/stills (multiple `<fanart><thumb>` tags from JAV scrapers)

## Limitations

- **Not App Store compatible** — uses `com.apple.security.temporary-exception.files.absolute-path.read-only` entitlement to load images from arbitrary directories
- **Debug builds** may conflict with XPC due to `.debug.dylib` injection; prefer Release configuration
- **No network images** — remote URLs in NFO files (e.g., TMDB/fanart.tv) are ignored; only local directory images are loaded
- **Scene release NFOs** (CP437 ASCII art) fall back to plain-text preview

## Test Cases

Tested with:
- **STARS-974** (JAV): 21 images (poster + backdrop + 19 stills), ~1.7 MB attachments (down from 42 MB raw)
- **Green Book** (movie): poster + fanart + clearlogo + cast info
- **Breaking Bad** (TV show): poster + fanart + logo + 6 season posters

## License

MIT
