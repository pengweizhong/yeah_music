import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
    override func awakeFromNib() {
        // 先交给 NSWindow/Nib 完成 outlet 与子视图加载；若 super 在最后调用，
        // 个别系统版本下会从 nib 再套一层内容，导致已设的 Flutter engine 丢失（Release 下更易出现）。
        super.awakeFromNib()

        let flutterViewController = FlutterViewController()
        let windowFrame = frame
        contentViewController = flutterViewController
        setFrame(windowFrame, display: true)

        RegisterGeneratedPlugins(registry: flutterViewController)

        let nativePluginKey = "com.pengwz.yeah_music.native"
        let registrar = flutterViewController.registrar(forPlugin: nativePluginKey)
        NSLog("YeahMusic: MainFlutterWindow → YeahMusicNativePlugin.register")
        YeahMusicNativePlugin.register(with: registrar)
    }
}
