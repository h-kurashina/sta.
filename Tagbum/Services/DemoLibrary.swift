#if DEBUG
import UIKit

/// Development fixtures use a separate store and never appear in release builds.
@MainActor
enum DemoLibrary {
    static func populate(_ store: LibraryStore) async {
        guard store.albums.isEmpty else { return }
        let subjects = ["物理学概論", "数学", "英語", "電磁気学"]
        for (index, name) in subjects.enumerated() {
            store.saveAlbum(name: name)
            guard let album = store.albums.last else { continue }
            let pages = (1...3).compactMap { page -> Data? in
                let renderer = UIGraphicsImageRenderer(size: CGSize(width: 840, height: 1188))
                return renderer.jpegData(withCompressionQuality: 0.9) { context in
                    UIColor.white.setFill(); context.fill(CGRect(x: 0, y: 0, width: 840, height: 1188))
                    func text(_ value: String, x: CGFloat, y: CGFloat, size: CGFloat, bold: Bool = false, color: UIColor = .darkGray) {
                        (value as NSString).draw(at: CGPoint(x: x, y: y), withAttributes: [.font: bold ? UIFont.boldSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size), .foregroundColor: color])
                    }
                    text("sta.  /  SAMPLE NOTES", x: 64, y: 55, size: 18, color: .systemIndigo)
                    text(name, x: 64, y: 115, size: 40, bold: true)
                    text("第\(page)回  講義ノート", x: 64, y: 180, size: 24)
                    let cg = context.cgContext
                    cg.setStrokeColor(UIColor.systemGray4.cgColor); cg.setLineWidth(1)
                    for row in 0..<23 { let y = CGFloat(270 + row * 34); cg.move(to: CGPoint(x: 64, y: y)); cg.addLine(to: CGPoint(x: 776, y: y)) }; cg.strokePath()
                    let lines: [String]
                    switch index {
                    case 0: lines = ["01  運動の法則", "力と加速度の関係を考える。", "F = ma", "運動量 p = mv", "エネルギー保存則", "E = ½mv² + mgh"]
                    case 1: lines = ["01  微分と積分", "関数の変化を調べる。", "f(x) = x²", "f′(x) = 2x", "曲線と面積", "∫ x² dx = x³/3 + C"]
                    case 2: lines = ["01  Reading & Writing", "A little progress, every day.", "Read. Think. Make a note.", "Key vocabulary", "perspective / evidence / context", "Write a short summary."]
                    default: lines = ["01  電場と電位", "電荷の周りに生じる場。", "F = qE", "V = W/q", "ガウスの法則", "電気力線と電束を考える。"]
                    }
                    for (row, line) in lines.enumerated() { text(line, x: 76, y: CGFloat(282 + row * 68), size: 25, bold: row == 0) }
                    text("サンプル資料 · \(page) / 3", x: 64, y: 1100, size: 17, color: .gray)
                }
            }
            _ = await store.addImages(pages, to: album.id)
        }
    }
}
#endif
