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

                // 读取已有书签
                var bookmarks = UserDefaults.standard.array(forKey: "musicDirBookmarks") as? [[String: Any]] ?? []

                let item: [String: Any] = [
                    "path": url.path, // 可识别标识
                    "bookmark": bookmark
                ]
                bookmarks.append(item)
                UserDefaults.standard.set(bookmarks, forKey: "musicDirBookmarks")

                result(url.path)
            } catch {
                result(FlutterError(code: "BOOKMARK_ERROR", message: "保存书签失败", details: error.localizedDescription))
            }
        } else {
            result(nil)
        }
    }

    // 如果传入 targetPath，只会恢复匹配的书签。
    // 如果不传，返回所有路径。
    private func restoreBookmark(result: @escaping FlutterResult, targetPath: String? = nil) {
        guard let items = UserDefaults.standard.array(forKey: "musicDirBookmarks") as? [[String: Any]] else {
            result([])
            return
        }

        var restoredPaths: [String] = []

        for item in items {
            guard let data = item["bookmark"] as? Data,
                  let path = item["path"] as? String else { continue }

            if let target = targetPath, target != path { continue }

            var isStale = false
            do {
                let url = try URL(resolvingBookmarkData: data, options: .withSecurityScope, relativeTo: nil, bookmarkDataIsStale: &isStale)
                if isStale { continue }
                if url.startAccessingSecurityScopedResource() {
                    restoredPaths.append(path)
                }
            } catch {
                continue
            }
        }

        result(restoredPaths) // 总是返回数组
    }



}
