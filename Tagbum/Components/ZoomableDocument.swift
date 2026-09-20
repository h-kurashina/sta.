import SwiftUI

/// UIScrollView preserves native pinch, pan and double-tap behavior on a page.
struct ZoomableDocument: UIViewRepresentable {
    let url: URL
    var onTap: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onTap: onTap) }
    func makeUIView(context: Context) -> UIScrollView {
        let scroll = DocumentScrollView()
        scroll.delegate = context.coordinator
        scroll.minimumZoomScale = 1
        scroll.maximumZoomScale = 5
        scroll.showsHorizontalScrollIndicator = false
        scroll.showsVerticalScrollIndicator = false
        let image = context.coordinator.imageView
        scroll.pageImage = image
        image.contentMode = .scaleAspectFit
        image.accessibilityLabel = "資料。ピンチまたはダブルタップで拡大"
        image.isAccessibilityElement = true
        scroll.addSubview(image)
        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.doubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        let singleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.singleTap))
        singleTap.require(toFail: doubleTap)
        scroll.addGestureRecognizer(doubleTap)
        scroll.addGestureRecognizer(singleTap)
        return scroll
    }
    func updateUIView(_ scroll: UIScrollView, context: Context) {
        context.coordinator.onTap = onTap
        if scroll.zoomScale == 1 { context.coordinator.imageView.frame = scroll.bounds }
        guard context.coordinator.url != url else { return }
        context.coordinator.url = url
        scroll.setZoomScale(1, animated: false)
        let coordinator = context.coordinator
        coordinator.task?.cancel()
        coordinator.task = Task { @MainActor in
            let image = await ImageStorage.shared.image(at: url, maxPixel: 3200)
            guard !Task.isCancelled else { return }
            coordinator.imageView.image = image
            coordinator.imageView.frame = scroll.bounds
        }
    }
    static func dismantleUIView(_ uiView: UIScrollView, coordinator: Coordinator) { coordinator.task?.cancel() }

    class Coordinator: NSObject, UIScrollViewDelegate {
        let imageView = UIImageView()
        var url: URL?
        var task: Task<Void, Never>?
        var onTap: () -> Void
        init(onTap: @escaping () -> Void) { self.onTap = onTap }
        func viewForZooming(in scrollView: UIScrollView) -> UIView? { imageView }
        @objc func singleTap() { onTap() }
        @objc func doubleTap(_ gesture: UITapGestureRecognizer) {
            guard let scroll = gesture.view as? UIScrollView else { return }
            if scroll.zoomScale > 1 { scroll.setZoomScale(1, animated: true) }
            else {
                let point = gesture.location(in: imageView)
                let size = CGSize(width: scroll.bounds.width / 2.5, height: scroll.bounds.height / 2.5)
                scroll.zoom(to: CGRect(x: point.x - size.width / 2, y: point.y - size.height / 2, width: size.width, height: size.height), animated: true)
            }
        }
    }
}

private final class DocumentScrollView: UIScrollView {
    weak var pageImage: UIImageView?
    override func layoutSubviews() {
        super.layoutSubviews()
        if zoomScale == 1 { pageImage?.frame = bounds; contentSize = bounds.size }
    }
}
