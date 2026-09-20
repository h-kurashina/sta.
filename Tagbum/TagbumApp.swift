import SwiftUI

@main
struct TagbumApp: App {
    @State private var store: LibraryStore

    init() {
        #if DEBUG
        let isolated = ProcessInfo.processInfo.arguments.contains("--demo") || ProcessInfo.processInfo.arguments.contains("--uitesting")
        let folder = ProcessInfo.processInfo.arguments.contains("--uitesting") ? "StaUITests" : "StaDemo"
        let root = isolated ? URL.applicationSupportDirectory.appending(path: folder) : nil
        if ProcessInfo.processInfo.arguments.contains("--uitesting"), let root {
            try? FileManager.default.removeItem(at: root)
        }
        _store = State(initialValue: LibraryStore(root: root))
        #else
        _store = State(initialValue: LibraryStore())
        #endif
    }
    var body: some Scene {
        WindowGroup {
            AlbumsView()
                .environment(store)
                .tint(Theme.accent)
                .task {
                    #if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("--demo") || ProcessInfo.processInfo.arguments.contains("--seed") {
                        await DemoLibrary.populate(store)
                    }
                    #endif
                }
                .alert("操作を完了できませんでした", isPresented: Binding(
                    get: { store.errorMessage != nil },
                    set: { if !$0 { store.errorMessage = nil } }
                )) { Button("閉じる", role: .cancel) { store.errorMessage = nil } }
                message: { Text(store.errorMessage ?? "") }
        }
    }
}
