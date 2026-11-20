# NFOPeek

macOS Quick Look extension for Emby/Kodi movie.nfo files.

## Features

- 🎬 Rich preview for movie.nfo files with poster and metadata
- 🖼️ Auto-loads poster and fanart images from the same directory
- 🌓 Supports light and dark mode
- 📄 Renders NFO metadata as a styled card with:
  - Title, year, runtime, rating
  - Genres and plot summary
  - Director, cast, studio info
  - Gallery of fanart/still images

## Requirements

- macOS 13.0+
- Xcode 15.0+ (for building)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (install via `brew install xcodegen`)

## Build & Install

```bash
# Generate Xcode project from project.yml
xcodegen generate

# Build Release configuration
xcodebuild -project NFOPeek.xcodeproj -scheme NFOPeek -configuration Release \
  -derivedDataPath build build

# Open the app once to activate the extension
open build/Build/Products/Release/NFOPeek.app

# Verify extension registration
pluginkit -m -p com.apple.quicklook.preview | grep NFOPeek
```

## Usage

1. Open NFOPeek.app once to register the Quick Look extension
2. Select any `.nfo` file in Finder
3. Press **Space** to trigger Quick Look preview
4. Enjoy the rich preview with poster and metadata

## Structure

```
NFOPeek/
├── App/                    # Host macOS application
│   ├── NFOPeekApp.swift
│   ├── ContentView.swift
│   └── Info.plist
├── Extension/              # Quick Look extension
│   ├── PreviewProvider.swift
│   └── Info.plist
└── Shared/                 # Shared parsing & rendering code
    ├── NFOMovie.swift      # NFO data model
    └── PreviewRenderer.swift  # HTML preview generator
```

## Technical Details

- **UTI**: Declares `org.kodi.nfo` as exported type for `.nfo` files
- **Sandbox**: Uses temporary exception for read-only file access to load sibling images
- **Rendering**: Returns HTML + image attachments via `QLPreviewReply`
- **Image lookup**: Prefers nfo-defined `<thumb>` tags, falls back to `poster.jpg`, `<basename>-poster.jpg`, `folder.jpg`

## Limitations

- Not compatible with Mac App Store distribution (uses sandbox exception entitlement)
- Debug builds may crash due to `.debug.dylib` injection conflicting with XPC; use Release
- Only supports movie.nfo format (TV shows/episodes not implemented)

## License

MIT
