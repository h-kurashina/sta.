import SwiftUI

struct DocumentThumbnail: View {
    let url: URL
    var maxPixel = 500
    var contentMode: ContentMode = .fill
    @State private var image: UIImage?
    @State private var finished = false

    var body: some View {
        GeometryReader { geometry in
            Group {
                if let image {
                    Image(uiImage: image).resizable().aspectRatio(contentMode: contentMode)
                } else if finished {
                    Image(systemName: "doc.text.image").font(.largeTitle).foregroundStyle(.secondary)
                } else {
                    ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .clipped()
        }
        .task(id: url) {
            image = nil
            finished = false
            let loaded = await ImageStorage.shared.image(at: url, maxPixel: maxPixel)
            guard !Task.isCancelled else { return }
            image = loaded
            finished = true
        }
    }
}
