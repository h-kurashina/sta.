import SwiftUI

struct DocumentViewer: View {
    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State var albumID: UUID
    @State var documentID: UUID
    @State private var chromeVisible = true
    @State private var deleting = false
    @Namespace private var tabAnimation
    private var documents: [Document] { store.documents(in: albumID) }
    private var selected: Document? { documents.first { $0.id == documentID } }

    var body: some View {
        VStack(spacing: 0) {
            if chromeVisible {
                HStack {
                    Button { dismiss() } label: { Image(systemName: "chevron.down").frame(width: 44, height: 44) }
                        .accessibilityLabel("資料を閉じる")
                    Spacer()
                    Text(store.album(albumID)?.name ?? "資料").font(.subheadline.weight(.semibold)).lineLimit(1)
                    Spacer()
                    Button { deleting = true } label: { Image(systemName: "trash").frame(width: 44, height: 44) }
                        .disabled(selected == nil).accessibilityLabel("表示中の資料を削除")
                }.padding(.horizontal, 12)
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(store.albums) { album in
                                Button {
                                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) {
                                        albumID = album.id
                                        documentID = store.documents(in: album.id).first?.id ?? UUID()
                                    }
                                } label: {
                                    Text(album.name).font(.subheadline.weight(album.id == albumID ? .semibold : .regular))
                                        .padding(.horizontal, 15).padding(.vertical, 10)
                                        .foregroundStyle(album.id == albumID ? Theme.accent : .secondary)
                                        .background {
                                            if album.id == albumID {
                                                Capsule().fill(Theme.accent.opacity(0.10)).matchedGeometryEffect(id: "subject", in: tabAnimation)
                                            }
                                        }
                                }.buttonStyle(.plain).id(album.id)
                                    .accessibilityAddTraits(album.id == albumID ? .isSelected : [])
                            }
                        }.padding(.horizontal, 16).padding(.vertical, 6)
                    }
                    .onAppear { proxy.scrollTo(albumID, anchor: .center) }
                    .onChange(of: albumID) { _, id in withAnimation { proxy.scrollTo(id, anchor: .center) } }
                }
            }
            if documents.isEmpty {
                ContentUnavailableView("まだ資料がありません", systemImage: "doc", description: Text("上のタブから別の科目を選べます。"))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TabView(selection: $documentID) {
                    ForEach(documents) { document in
                        ZoomableDocument(url: store.url(for: document)) {
                            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.18)) { chromeVisible.toggle() }
                        }.tag(document.id).padding(.horizontal, 4)
                    }
                }
                .id(albumID)
                .tabViewStyle(.page(indexDisplayMode: .never))
            }
            if chromeVisible {
                HStack {
                    if let selected { Text(selected.createdAt, format: .dateTime.year().month().day()) }
                    Spacer()
                    Text("\(documents.firstIndex(where: { $0.id == documentID }).map { $0 + 1 } ?? 0) / \(documents.count)")
                        .monospacedDigit()
                }.font(.caption).foregroundStyle(.secondary).padding(.horizontal, 24).padding(.vertical, 16)
            }
        }
        .background(Color(uiColor: .secondarySystemBackground))
        .statusBarHidden(!chromeVisible)
        .alert("この資料を削除しますか？", isPresented: $deleting) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                guard let selected else { return }
                let index = documents.firstIndex(of: selected) ?? 0
                if store.deleteDocument(selected) {
                    let remaining = documents
                    documentID = remaining.isEmpty ? UUID() : remaining[min(index, remaining.count - 1)].id
                }
            }
        } message: { Text("この操作は取り消せません。") }
    }
}
