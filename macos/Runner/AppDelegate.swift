import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    override func applicationDidFinishLaunching(_ notification: Notification) {
        super.applicationDidFinishLaunching(notification)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(Self.yeahMusicMainWindowWillClose(_:)),
            name: NSWindow.willCloseNotification,
            object: nil
        )

        // Release 包里窗口/Flutter 就绪时机可能比 Debug 略晚：多拍几次兜底，避免出现 MissingPluginException。
        YeahMusicMethodChannels.registerFromFirstFlutterViewController(reason: "appDidFinishLaunch(sync)")
        DispatchQueue.main.async {
            YeahMusicMethodChannels.registerFromFirstFlutterViewController(reason: "appDidFinishLaunch(+0 async)")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            YeahMusicMethodChannels.registerFromFirstFlutterViewController(reason: "appDidFinishLaunch(+0.08)")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            YeahMusicMethodChannels.registerFromFirstFlutterViewController(reason: "appDidFinishLaunch(+0.35)")
        }
    }

    /// 关闭主窗口时一并关闭多窗口引擎（如桌面歌词），否则进程仍存活且 Dock 行为异常。
    @objc private func yeahMusicMainWindowWillClose(_ note: Notification) {
        guard let closing = note.object as? NSWindow else { return }
        guard let appDel = NSApplication.shared.delegate as? FlutterAppDelegate,
              let main = appDel.mainFlutterWindow else { return }
        guard closing === main else { return }
        for w in NSApp.windows where w !== main {
            w.close()
        }
    }
}
