import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    let channelName = "com.pengwz.yeah_music/bookmark"

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    override func applicationDidFinishLaunching(_ notification: Notification) {
        let controller = mainFlutterWindow?.contentViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: controller.engine.binaryMessenger)

        channel.setMethodCallHandler { (call, result) in
            switch call.method {
            case "pickDirectory":
                self.pickDirectory(result: result)
            case "restoreBookmark":
                self.restoreBookmark(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        super.applicationDidFinishLaunching(notification)
    }

    private func pickDirectory(result: @escaping FlutterResult) {
        let panel = NSOpenPanel()
        panel.title = "选择音乐目录"
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let bookmark = try url.bookmarkData(options: .withSecurityScope, includingResourceValuesForKeys: nil, relativeTo: nil)
                UserDefaults.standard.set(bookmark, forKey: "musicDirBookmark")
                result(url.path)
            } catch {
                result(FlutterError(code: "BOOKMARK_ERROR", message: "保存书签失败", details: error.localizedDescription))
            }
        } else {
            result(nil)
        }
    }

    private func restoreBookmark(result: @escaping FlutterResult) {
        guard let data = UserDefaults.standard.data(forKey: "musicDirBookmark") else {
            result(nil)
            return
        }

        var isStale = false
        do {
            let url = try URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
            if isStale {
                result(nil)
                return
            }
            if url.startAccessingSecurityScopedResource() {
                result(url.path)
            } else {
                result(nil)
            }
        } catch {
            result(nil)
        }
    }
}
