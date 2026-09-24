import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    self.contentViewController = flutterViewController

    // Open at a comfortable desktop size (the template default is 800×600).
    let visible = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
    let width = min(1180, visible.width - 80)
    let height = min(800, visible.height - 80)
    let frame = NSRect(
      x: visible.midX - width / 2,
      y: visible.midY - height / 2,
      width: width,
      height: height
    )
    self.setFrame(frame, display: true)
    self.minSize = NSSize(width: 720, height: 560)

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
