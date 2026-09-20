import SwiftUI

struct AlbumsView: View {
    @Environment(LibraryStore.self) private var store
    @State private var creating = false
    @State private var editing: Album?
    @State private var deleting: Album?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 26) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("学びを、ひとまとめに。")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("科目を選んで、撮るだけ。")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }.padding(.top, 16)

                    HStack {
                        Text("MY SUBJECTS").font(.system(size: 11, weight: .semibold, design: .rounded)).tracking(2)
                        Spacer()
                        Text("\(store.albums.count) 科目").font(.caption)
                    }.foregroundStyle(.secondary)

                    if store.albums.isEmpty {
                        VStack(spacing: 20) {
                            FolderCard(album: Album(name: "最初の科目", colorIndex: 0))
                                .frame(width: 165).accessibilityHidden(true)
                            Text("プリントの居場所をつくろう")
                                .font(.headline)
                            Text("授業ごとにまとめれば、\n必要な資料がすぐに見つかります。")
                                .font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
                            Button { creating = true } label: {
                                Label("科目を作成", systemImage: "plus").padding(.horizontal, 12).padding(.vertical, 6)
                            }.buttonStyle(.borderedProminent).clipShape(Capsule())
                        }.frame(maxWidth: .infinity).padding(.top, 10)
                    } else {
                        LazyVGrid(columns: [GridItem(.flexible(), spacing: 24), GridItem(.flexible(), spacing: 24)], alignment: .leading, spacing: 28) {
                            ForEach(store.albums) { album in
                                NavigationLink(value: album.id) { FolderCard(album: album) }
                                    .buttonStyle(.plain)
                                    .contextMenu {
                                        Button("科目名を編集", systemImage: "pencil") { editing = album }
                                        Button("科目を削除", systemImage: "trash", role: .destructive) { deleting = album }
                                    }
                            }
                        }
                        HStack(spacing: 6) {
                            Image(systemName: "lock").font(.caption2)
                            Text("資料はこのデバイスに保存されます").font(.caption2)
                        }.foregroundStyle(.tertiary).frame(maxWidth: .infinity).padding(.top, 12)
                    }
                }.padding(.horizontal, 24).padding(.bottom, 30)
            }
            .background(Theme.background)
            .navigationTitle("sta.")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Image("StaLogo").resizable().scaledToFit().frame(width: 70, height: 35)
                        .accessibilityLabel("sta.")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { creating = true } label: { Image(systemName: "plus").fontWeight(.medium) }
                        .accessibilityLabel("新しい科目を作成").accessibilityIdentifier("newAlbum")
                }
            }
            .navigationDestination(for: UUID.self) { AlbumDetailView(albumID: $0) }
            .sheet(isPresented: $creating) { AlbumEditor() }
            .sheet(item: $editing) { AlbumEditor(album: $0) }
            .alert("科目を削除しますか？", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
                Button("キャンセル", role: .cancel) { deleting = nil }
                Button("削除", role: .destructive) { if let deleting { store.deleteAlbum(deleting) }; deleting = nil }
            } message: { Text("「\(deleting?.name ?? "")」と中の資料を削除します。この操作は取り消せません。") }
            .disabled(store.loadFailed)
        }
    }
}
