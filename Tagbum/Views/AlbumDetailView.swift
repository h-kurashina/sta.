import SwiftUI
import PhotosUI
import VisionKit
import AVFoundation

struct AlbumDetailView: View {
    @Environment(LibraryStore.self) private var store
    let albumID: UUID
    @State private var showingScanner = false
    @State private var showingPhotos = false
    @State private var photoItems: [PhotosPickerItem] = []
    @State private var selectedDocument: Document?
    @State private var deleting: Document?
    @State private var editing = false
    @State private var isSaving = false
    @State private var status: String?
    @State private var cameraMessage: String?
    @State private var pendingPages: [Data] = []
    private var documents: [Document] { store.documents(in: albumID) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text("\(documents.count)枚の資料").font(.subheadline).foregroundStyle(.secondary)
                    Spacer()
                    Text("新しい順").font(.caption).foregroundStyle(.tertiary)
                }
                if documents.isEmpty {
                    ContentUnavailableView {
                        Label("最初のプリントを残そう", systemImage: "doc.viewfinder")
                    } description: {
                        Text("右下のスキャンをタップ。\n撮った資料は、この科目に保存されます。")
                    } actions: {
                        Button("写真から追加", systemImage: "photo") { showingPhotos = true }
                    }.padding(.top, 70)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 22) {
                        ForEach(documents) { document in
                            Button { selectedDocument = document } label: {
                                VStack(alignment: .leading, spacing: 8) {
                                    DocumentThumbnail(url: store.url(for: document))
                                        .aspectRatio(0.72, contentMode: .fit)
                                        .background(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(.primary.opacity(0.06)))
                                    Text(document.createdAt, format: .dateTime.month().day())
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("\(document.createdAt.formatted(date: .abbreviated, time: .omitted))の資料、\(document.order + 1)ページ目")
                            .contextMenu {
                                Button("資料を削除", systemImage: "trash", role: .destructive) { deleting = document }
                            }
                        }
                    }
                }
            }.padding(24).padding(.bottom, 100)
        }
        .background(Theme.background)
        .navigationTitle(store.album(albumID)?.name ?? "科目")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button("写真から追加", systemImage: "photo.on.rectangle") { showingPhotos = true }
                    Button("科目名を編集", systemImage: "pencil") { editing = true }
                } label: { Image(systemName: "ellipsis") }
                .accessibilityLabel("科目のメニュー")
            }
        }
        .overlay(alignment: .bottomTrailing) {
            Button(action: startScan) {
                Label("スキャン", systemImage: "viewfinder")
                    .font(.system(size: 17, weight: .semibold))
                    .padding(.horizontal, 25).padding(.vertical, 20)
                    .foregroundStyle(.white).background(Theme.accent, in: Capsule())
                    .shadow(color: Theme.accent.opacity(0.16), radius: 10, y: 5)
            }
            .accessibilityIdentifier("scanDocument")
            .contextMenu { Button("写真から追加", systemImage: "photo") { showingPhotos = true } }
            .padding(24)
        }
        .overlay(alignment: .top) {
            if !pendingPages.isEmpty && !isSaving {
                Button { Task { await savePendingPages() } } label: {
                    Label("未保存の資料を再保存", systemImage: "arrow.clockwise")
                        .font(.subheadline).padding(12).background(.regularMaterial, in: Capsule())
                }.padding(.top, 8)
            } else if let status {
                Label(status, systemImage: "checkmark.circle.fill")
                    .font(.subheadline).padding(12).background(.regularMaterial, in: Capsule())
                    .padding(.top, 8).allowsHitTesting(false)
                    .task { try? await Task.sleep(for: .seconds(2)); self.status = nil }
            }
        }
        .disabled(isSaving)
        .overlay {
            if isSaving {
                ZStack {
                    Color.black.opacity(0.12).ignoresSafeArea()
                    ProgressView("この科目に保存中…").padding(28).background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
                }
            }
        }
        .fullScreenCover(isPresented: $showingScanner) {
            DocumentScanner { pages in
                showingScanner = false
                pendingPages = pages
                Task { await savePendingPages() }
            } onCancel: {
                showingScanner = false
            } onError: { error in
                showingScanner = false
                cameraMessage = error.localizedDescription
            }.ignoresSafeArea()
        }
        .photosPicker(isPresented: $showingPhotos, selection: $photoItems, maxSelectionCount: 30, selectionBehavior: .ordered, matching: .images)
        .onChange(of: photoItems) { _, items in
            guard !items.isEmpty else { return }
            Task { await importPhotos(items) }
        }
        .fullScreenCover(item: $selectedDocument) { document in
            DocumentViewer(albumID: albumID, documentID: document.id)
        }
        .sheet(isPresented: $editing) { AlbumEditor(album: store.album(albumID)) }
        .alert("資料を削除しますか？", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
            Button("キャンセル", role: .cancel) { deleting = nil }
            Button("削除", role: .destructive) { if let deleting { store.deleteDocument(deleting) }; deleting = nil }
        } message: { Text("この操作は取り消せません。") }
        .alert("スキャナー", isPresented: Binding(get: { cameraMessage != nil }, set: { if !$0 { cameraMessage = nil } })) {
            Button("写真から追加") { showingPhotos = true }
            Button("閉じる", role: .cancel) {}
        } message: { Text(cameraMessage ?? "") }
    }

    private func startScan() {
        if !pendingPages.isEmpty { Task { await savePendingPages() }; return }
        guard VNDocumentCameraViewController.isSupported else {
            cameraMessage = "この環境ではカメラの書類スキャンを利用できません。写真から資料を追加できます。実機では書類の自動認識・補正が利用できます。"
            return
        }
        Task {
            let authorized: Bool
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: authorized = true
            case .notDetermined: authorized = await AVCaptureDevice.requestAccess(for: .video)
            default: authorized = false
            }
            if authorized { showingScanner = true }
            else { cameraMessage = "カメラを使用するには、設定アプリでsta.のカメラアクセスを許可してください。" }
        }
    }

    private func importPhotos(_ items: [PhotosPickerItem]) async {
        isSaving = true
        defer { isSaving = false; photoItems = [] }
        do {
            var data: [Data] = []
            for item in items {
                guard let image = try await item.loadTransferable(type: Data.self) else { throw CocoaError(.fileReadCorruptFile) }
                data.append(image)
            }
            pendingPages = data
            await savePendingPages()
        } catch { store.errorMessage = "写真を読み込めませんでした。もう一度選択してください。\n\(error.localizedDescription)" }
    }

    private func savePendingPages() async {
        guard !pendingPages.isEmpty else { return }
        isSaving = true
        let count = pendingPages.count
        let succeeded = await store.addImages(pendingPages, to: albumID)
        isSaving = false
        if succeeded {
            pendingPages = []
            status = "\(count)枚を保存しました"
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
        // Keep image data available for retry even if storage is full.
    }
}
