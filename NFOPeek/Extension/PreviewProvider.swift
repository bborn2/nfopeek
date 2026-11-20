import Cocoa
import OSLog
import QuickLookUI
import UniformTypeIdentifiers

private let log = Logger(subsystem: "com.kunsong.NFOPeek.Extension", category: "preview")

class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    private let previewSize = CGSize(width: 900, height: 1000)

    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let nfoURL = request.fileURL
        log.info("preview requested: \(nfoURL.path, privacy: .public)")

        guard let preview = PreviewRenderer.renderMoviePreview(nfoURL: nfoURL) else {
            log.info("not a <movie> nfo, falling back to plain text")
            return plainTextReply(for: nfoURL)
        }
        log.info("rendered movie preview with \(preview.images.count) images")

        let htmlData = Data(preview.html.utf8)
        let reply = QLPreviewReply(dataOfContentType: .html, contentSize: previewSize) { _ in htmlData }
        reply.stringEncoding = .utf8
        // Images are referenced from the HTML as cid:<id>.
        for (id, imageData) in preview.images {
            let type = UTType(filenameExtension: (id as NSString).pathExtension) ?? .jpeg
            reply.attachments[id] = QLPreviewReplyAttachment(data: imageData, contentType: type)
        }
        return reply
    }

    /// Scene-release .nfo files are plain text (often CP437 ASCII art), not XML.
    private func plainTextReply(for url: URL) -> QLPreviewReply {
        let data = (try? Data(contentsOf: url)) ?? Data()
        let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) ?? ""
        let reply = QLPreviewReply(dataOfContentType: .plainText, contentSize: previewSize) { _ in
            Data(text.utf8)
        }
        reply.stringEncoding = .utf8
        return reply
    }
}
