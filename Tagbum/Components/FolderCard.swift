import SwiftUI

struct FolderCard: View {
    @Environment(LibraryStore.self) private var store
    let album: Album
    private var documents: [Document] { store.documents(in: album.id) }
    private var color: Color { Theme.colors[album.colorIndex % Theme.colors.count] }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GeometryReader { geometry in
                ZStack(alignment: .bottom) {
                    UnevenRoundedRectangle(topLeadingRadius: 8, bottomLeadingRadius: 14, bottomTrailingRadius: 14, topTrailingRadius: 14)
                        .fill(color.opacity(0.65)).frame(height: 118)
                    RoundedRectangle(cornerRadius: 6).fill(color.opacity(0.65))
                        .frame(width: 64, height: 22).offset(x: -geometry.size.width / 2 + 38, y: -104)
                    ForEach((0..<3).reversed(), id: \.self) { index in
                        ZStack(alignment: .topLeading) {
                            RoundedRectangle(cornerRadius: 5).fill(.white)
                            if documents.indices.contains(index) {
                                DocumentThumbnail(url: store.url(for: documents[index]))
                                    .clipShape(RoundedRectangle(cornerRadius: 4))
                            } else {
                                VStack(alignment: .leading, spacing: 7) {
                                    RoundedRectangle(cornerRadius: 1).fill(color).frame(width: 42, height: 4)
                                    ForEach(0..<5, id: \.self) { row in
                                        RoundedRectangle(cornerRadius: 1).fill(Color.black.opacity(0.055))
                                            .frame(width: row == 4 ? 52 : nil, height: 2)
                                    }
                                }.padding(13)
                            }
                        }
                        .frame(width: geometry.size.width - 32, height: 123)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(.black.opacity(0.035)))
                        .rotationEffect(.degrees(index == 1 ? -7 : index == 2 ? 5 : 0))
                        .offset(y: CGFloat(-15 - index * 7))
                    }
                    UnevenRoundedRectangle(topLeadingRadius: 6, bottomLeadingRadius: 13, bottomTrailingRadius: 13, topTrailingRadius: 6)
                        .fill(LinearGradient(colors: [color, color.opacity(0.92)], startPoint: .top, endPoint: .bottom))
                        .frame(height: 88)
                        .overlay(alignment: .bottomLeading) {
                            HStack(spacing: 5) {
                                Image(systemName: "doc.text").font(.system(size: 10))
                                Text("\(documents.count)").font(.system(size: 11, weight: .medium, design: .rounded))
                            }.foregroundStyle(.black.opacity(0.45)).padding(13)
                        }
                }
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .bottom)
            }.frame(height: 170)
            VStack(alignment: .leading, spacing: 5) {
                Text(album.name).font(.system(.headline, design: .rounded)).foregroundStyle(.primary).lineLimit(2)
                HStack(spacing: 4) {
                    Text("\(documents.count)枚")
                    Text("·")
                    Text(album.updatedAt, format: .dateTime.month().day())
                }.font(.caption).foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(album.name)、資料\(documents.count)枚")
    }
}
