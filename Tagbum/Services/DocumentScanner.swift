import SwiftUI
import VisionKit

struct DocumentScanner: UIViewControllerRepresentable {
    var onComplete: ([Data]) -> Void
    var onCancel: () -> Void
    var onError: (Error) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }
    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }

    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let parent: DocumentScanner
        init(parent: DocumentScanner) { self.parent = parent }
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) { parent.onCancel() }
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) { parent.onError(error) }
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            var pages: [Data] = []
            for index in 0..<scan.pageCount {
                guard let data = autoreleasepool(invoking: { scan.imageOfPage(at: index).jpegData(compressionQuality: 0.95) }) else {
                    parent.onError(CocoaError(.fileReadCorruptFile)); return
                }
                pages.append(data)
            }
            parent.onComplete(pages)
        }
    }
}
