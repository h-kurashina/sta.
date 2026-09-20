import AppKit
import Foundation
let root = URL(fileURLWithPath: CommandLine.arguments[1])
func render(size: Int, icon: Bool, destination: String) {
    let height = icon ? size : size / 2
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let context = NSGraphicsContext.current!.cgContext
    if icon { context.setFillColor(NSColor(calibratedRed: 0.965, green: 0.963, blue: 0.946, alpha: 1).cgColor); context.fill(CGRect(x: 0, y: 0, width: size, height: height)) }
    context.translateBy(x: 0, y: CGFloat(height))
    context.scaleBy(x: 1, y: -1)
    let scale = CGFloat(size) / (icon ? 300 : 240)
    if icon { context.translateBy(x: CGFloat(size) * 0.10, y: CGFloat(height) * 0.30) }
    context.scaleBy(x: scale, y: scale)
    context.setLineWidth(14); context.setLineCap(.round); context.setLineJoin(.round)
    func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat) -> CGColor { NSColor(calibratedRed:r/255, green:g/255, blue:b/255, alpha:1).cgColor }
    context.setStrokeColor(color(141,134,207))
    context.move(to: CGPoint(x:65,y:40)); context.addCurve(to: CGPoint(x:24,y:49), control1: CGPoint(x:53,y:31), control2: CGPoint(x:24,y:32)); context.addCurve(to: CGPoint(x:66,y:74), control1: CGPoint(x:24,y:66), control2: CGPoint(x:66,y:56)); context.addCurve(to: CGPoint(x:22,y:83), control1: CGPoint(x:66,y:93), control2: CGPoint(x:36,y:94)); context.strokePath()
    context.setStrokeColor(color(109,184,172))
    context.move(to: CGPoint(x:99,y:20)); context.addLine(to: CGPoint(x:99,y:74)); context.addQuadCurve(to: CGPoint(x:116,y:85), control: CGPoint(x:99,y:89)); context.move(to: CGPoint(x:82,y:41)); context.addLine(to: CGPoint(x:119,y:41)); context.strokePath()
    context.setStrokeColor(color(82,109,169))
    context.move(to: CGPoint(x:175,y:42)); context.addLine(to: CGPoint(x:175,y:86)); context.move(to: CGPoint(x:174,y:55)); context.addCurve(to: CGPoint(x:132,y:63), control1: CGPoint(x:174,y:30), control2: CGPoint(x:132,y:33)); context.addCurve(to: CGPoint(x:174,y:69), control1: CGPoint(x:132,y:93), control2: CGPoint(x:174,y:95)); context.strokePath()
    context.setFillColor(color(109,184,172)); context.fillEllipse(in: CGRect(x:198,y:76,width:16,height:16))
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: root.appendingPathComponent(destination))
}
render(size: 1024, icon: true, destination: "Tagbum/Assets.xcassets/AppIcon.appiconset/sta-icon.png")
render(size: 720, icon: false, destination: "Tagbum/Assets.xcassets/StaLogo.imageset/sta-logo.png")
