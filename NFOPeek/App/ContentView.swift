import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text.image")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)

            Text("NFOPeek")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Quick Look extension for Emby movie.nfo files")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Divider()
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 8) {
                    Text("1.")
                        .fontWeight(.semibold)
                    Text("Open this app once to activate the Quick Look extension")
                }

                HStack(alignment: .top, spacing: 8) {
                    Text("2.")
                        .fontWeight(.semibold)
                    Text("Select any .nfo file in Finder and press Space")
                }

                HStack(alignment: .top, spacing: 8) {
                    Text("3.")
                        .fontWeight(.semibold)
                    Text("Enjoy a rich preview with poster, metadata, and stills")
                }
            }
            .font(.callout)
            .frame(maxWidth: 400, alignment: .leading)

            Spacer()

            Text("The extension only reads .nfo files and images locally. No network access.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(40)
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview {
    ContentView()
}
