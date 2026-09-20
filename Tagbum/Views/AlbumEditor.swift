import SwiftUI

struct AlbumEditor: View {
    @Environment(LibraryStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var album: Album?
    @State private var name = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            Form {
                TextField("科目名（例：物理学概論）", text: $name)
                    .focused($focused).submitLabel(.done).onSubmit(save)
                    .accessibilityIdentifier("albumName")
            }
            .navigationTitle(album == nil ? "新しい科目" : "科目名を編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("キャンセル") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button(album == nil ? "作成" : "保存", action: save)
                        .fontWeight(.semibold)
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .accessibilityIdentifier("saveAlbum")
                }
            }
            .onAppear { name = album?.name ?? ""; focused = true }
        }
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.visible)
    }

    private func save() {
        if store.saveAlbum(name: name, editing: album) { dismiss() }
    }
}
