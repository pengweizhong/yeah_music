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
}
