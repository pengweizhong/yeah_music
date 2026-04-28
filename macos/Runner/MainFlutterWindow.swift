import Cocoa
import FlutterMacOS
import desktop_multi_window

/// desktop_multi_window 子窗口默认带标题栏且不透明；本应用仅用于歌词小窗。
/// [setOnWindowCreatedCallback] 只会在新建子引擎时触发，此处统一做成透明无边框。
/// Dart 侧在 macOS 勿调用 [setAsFrameless]（会把 isOpaque 设为 true）。
enum YeahMusicDesktopLyricsWindowConfigurator {
    static func applyForChildEngine(controller: FlutterViewController) {
        guard let window = controller.view.window else { return }

        window.styleMask = [.borderless, .resizable]
        window.isOpaque = false
        window.backgroundColor = .clear
        /// 与 Dart 侧一致：阴影在透明小窗上易被看成「边框」。
        window.hasShadow = false
        window.title = ""
        window.titlebarAppearsTransparent = true
        window.collectionBehavior.insert(.canJoinAllSpaces)
        window.collectionBehavior.insert(.fullScreenAuxiliary)

        controller.backgroundColor = .clear

        DispatchQueue.main.async {
            Self.reapplyChrome(window: window, controller: controller)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            Self.reapplyChrome(window: window, controller: controller)
        }
    }

    private static func reapplyChrome(window: NSWindow, controller: FlutterViewController) {
        window.styleMask = [.borderless, .resizable]
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        controller.backgroundColor = .clear
    }
}

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

        FlutterMultiWindowPlugin.setOnWindowCreatedCallback { controller in
            RegisterGeneratedPlugins(registry: controller)
            YeahMusicDesktopLyricsWindowConfigurator.applyForChildEngine(controller: controller)
            YeahMusicDesktopLyricsMousePlugin.register(
                with: controller.registrar(forPlugin: "yeah_music.desktop_lyrics_mouse")
            )
        }

        let nativePluginKey = "com.pengwz.yeah_music.native"
        let registrar = flutterViewController.registrar(forPlugin: nativePluginKey)
        NSLog("YeahMusic: MainFlutterWindow → YeahMusicNativePlugin.register")
        YeahMusicNativePlugin.register(with: registrar)
    }
}
