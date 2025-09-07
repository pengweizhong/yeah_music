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

        // bookmark channel
        let bookmarkChannel = FlutterMethodChannel(name: channelName,
                                                   binaryMessenger: controller.engine.binaryMessenger)

        bookmarkChannel.setMethodCallHandler { (call, result) in
            switch call.method {
            case "pickDirectory":
                self.pickDirectory(result: result)
            case "restoreBookmark":
                self.restoreBookmark(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        // disk space channel
        let diskSpaceChannel = FlutterMethodChannel(name: "disk_space",
                                                    binaryMessenger: controller.engine.binaryMessenger)

        diskSpaceChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            if call.method == "getDiskSpace" {
                self.getDiskSpace(result: result)
            } else {
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
                let bookmark = try url.bookmarkData(options: .withSecurityScope,
                                                    includingResourceValuesForKeys: nil,
                                                    relativeTo: nil)

                var bookmarks = UserDefaults.standard.array(forKey: "musicDirBookmarks") as? [[String: Any]] ?? []

                let item: [String: Any] = [
                    "path": url.path,
                    "bookmark": bookmark
                ]
                bookmarks.append(item)
                UserDefaults.standard.set(bookmarks, forKey: "musicDirBookmarks")

                result(url.path)
            } catch {
                result(FlutterError(code: "BOOKMARK_ERROR",
                                    message: "保存书签失败",
                                    details: error.localizedDescription))
            }
        } else {
            result(nil)
        }
    }

    private func restoreBookmark(result: @escaping FlutterResult, targetPath: String? = nil) {
        guard let items = UserDefaults.standard.array(forKey: "musicDirBookmarks") as? [[String: Any]] else {
            result([])
            return
        }

        var restoredPaths: [String] = []

        for item in items {
            guard let data = item["bookmark"] as? Data,
                  let path = item["path"] as? String
            else {
                continue
            }

            if let target = targetPath, target != path {
                continue
            }

            var isStale = false
            do {
                let url = try URL(resolvingBookmarkData: data,
                                  options: .withSecurityScope,
                                  relativeTo: nil,
                                  bookmarkDataIsStale: &isStale)
                if isStale {
                    continue
                }

                if url.startAccessingSecurityScopedResource() {
                    restoredPaths.append(path)
                }
            } catch {
                continue
            }
        }

        result(restoredPaths)
    }

    private func getDiskSpace(result: FlutterResult) {
        do {
            let attrs = try FileManager.default.attributesOfFileSystem(forPath: "/")
            if let total = attrs[.systemSize] as? NSNumber,
               let free = attrs[.systemFreeSize] as? NSNumber {
                result([
                           "total": total.int64Value,
                           "free": free.int64Value
                       ])
            } else {
                result(FlutterError(code: "UNAVAILABLE",
                                    message: "Disk space info not available",
                                    details: nil))
            }
        } catch {
            result(FlutterError(code: "ERROR",
                                message: "Failed to get disk space: \(error.localizedDescription)",
                                details: nil))
        }
    }
}
