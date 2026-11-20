import Cocoa
import OSLog
import QuickLookUI
import UniformTypeIdentifiers

private let log = Logger(subsystem: "com.kunsong.NFOPeek.Extension", category: "preview")

class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    private let previewSize = CGSize(width: 1100, height: 900)

    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let nfoURL = request.fileURL
        let data = try Data(contentsOf: nfoURL)

        guard let item = NFOParser.parse(data) else {
            log.info("not an XML nfo, showing as text: \(nfoURL.lastPathComponent, privacy: .public)")
            return plainTextReply(data)
        }

        let store = ImageStore(baseDir: nfoURL.deletingLastPathComponent())
        let art = Artwork.resolve(item, nfoURL: nfoURL)
        let html = HTMLRenderer(item: item, art: art, store: store).render()
        log.info("\(nfoURL.lastPathComponent, privacy: .public): \(store.images.count) images")

        let reply = QLPreviewReply(dataOfContentType: .html, contentSize: previewSize) { _ in Data(html.utf8) }
        reply.stringEncoding = .utf8
        for (id, imageData) in store.images {
            let type = UTType(filenameExtension: (id as NSString).pathExtension) ?? .image
            reply.attachments[id] = QLPreviewReplyAttachment(data: imageData, contentType: type)
        }
        return reply
    }

    /// Scene-release .nfo files are plain text, often CP437 ASCII art.
    private func plainTextReply(_ data: Data) -> QLPreviewReply {
        let text = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: String.Encoding(rawValue: CFStringConvertEncodingToNSStringEncoding(
                CFStringEncoding(CFStringEncodings.dosLatinUS.rawValue))))
            ?? String(decoding: data, as: UTF8.self)
        let reply = QLPreviewReply(dataOfContentType: .plainText, contentSize: previewSize) { _ in Data(text.utf8) }
        reply.stringEncoding = .utf8
        return reply
    }
}
