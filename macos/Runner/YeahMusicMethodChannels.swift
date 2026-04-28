import Cocoa
import FlutterMacOS

/// 必须在主窗口 [FlutterViewController] 创建并 [RegisterGeneratedPlugins] 之后注册，
/// 早于此时 [NSApp.windows] / [mainFlutterWindow] 往往仍为空，会导致 MissingPluginException。
enum YeahMusicMethodChannels {
    /// 启动过程中任意时刻：只要主窗上已有 FlutterViewController，便把通道挂上去（可多调几次，等价于重置 handler）。
    static func registerFromFirstFlutterViewController(reason: String) {
        if let appDel = NSApplication.shared.delegate as? FlutterAppDelegate,
           let fv = appDel.mainFlutterWindow?.contentViewController as? FlutterViewController {
            NSLog("YeahMusic: \(reason) — via mainFlutterWindow")
            registerAll(messenger: fv.engine.binaryMessenger)
            return
        }
        guard !NSApp.windows.isEmpty else {
            NSLog("YeahMusic: \(reason) — skip register, NSApp.windows is empty")
            return
        }
        for window in NSApp.windows {
            if let fv = window.contentViewController as? FlutterViewController {
                NSLog("YeahMusic: \(reason) — register channels (window=\(window.title))")
                registerAll(messenger: fv.engine.binaryMessenger)
                return
            }
        }
        NSLog("YeahMusic: \(reason) — no FlutterViewController (\(NSApp.windows.count) windows)")
    }

    static func registerAll(messenger: FlutterBinaryMessenger) {
        let bookmark = FlutterMethodChannel(name: "com.pengwz.yeah_music/bookmark",
                                            binaryMessenger: messenger)
        bookmark.setMethodCallHandler { call, result in
            switch call.method {
            case "pickDirectory":
                Self.pickDirectory(result: result)
            case "restoreBookmark":
                let path = call.arguments as? String
                Self.restoreBookmark(result: result, targetPath: path)
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        let diskSpace = FlutterMethodChannel(name: "disk_space",
                                             binaryMessenger: messenger)
        diskSpace.setMethodCallHandler { call, result in
            guard call.method == "getDiskSpace" else {
                result(FlutterMethodNotImplemented)
                return
            }
            Self.getDiskSpace(result: result)
        }

        let menuBar = FlutterMethodChannel(name: "yeah_music/menu_bar_lyrics",
                                           binaryMessenger: messenger)
        MenuBarLyricsController.shared.attachFlutterMessenger(messenger)
        menuBar.setMethodCallHandler { call, result in
            switch call.method {
            case "setVisible":
                let visible = call.arguments as? Bool ?? false
                MenuBarLyricsController.shared.setVisible(visible)
                result(nil)
            case "setText":
                MenuBarLyricsController.shared.setText((call.arguments as? String) ?? "")
                result(nil)
            case "setMenuBarState":
                let args = call.arguments as? [String: Any] ?? [:]
                MenuBarLyricsController.shared.setMenuBarState(
                    isPlaying: args["isPlaying"] as? Bool ?? false,
                    trackTitle: args["trackTitle"] as? String ?? "",
                    trackArtist: args["trackArtist"] as? String ?? "",
                    playPauseTitle: args["playPauseTitle"] as? String ?? "Play",
                    previousTitle: args["previousTitle"] as? String ?? "Previous",
                    nextTitle: args["nextTitle"] as? String ?? "Next"
                )
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private static func pickDirectory(result: @escaping FlutterResult) {
        DispatchQueue.main.async {
            let panel = NSOpenPanel()
            panel.title = "选择音乐目录"
            panel.canChooseDirectories = true
            panel.canChooseFiles = false
            panel.allowsMultipleSelection = false

            guard panel.runModal() == .OK, let url = panel.url else {
                result(nil)
                return
            }

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
        }
    }

    private static func restoreBookmark(result: @escaping FlutterResult, targetPath: String? = nil) {
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

    private static func getDiskSpace(result: FlutterResult) {
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

/// 悬浮歌词子窗口：锁定拖动时由 Dart 打开整窗鼠标穿透，点击落到下层应用。
final class YeahMusicDesktopLyricsMousePlugin: NSObject, FlutterPlugin {
    private weak var anchorView: NSView?

    static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "yeah_music/desktop_lyrics_mouse",
            binaryMessenger: registrar.messenger
        )
        let instance = YeahMusicDesktopLyricsMousePlugin()
        instance.anchorView = registrar.view
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "setIgnoresMouseEvents":
            let ignore = (call.arguments as? [String: Any])?["ignore"] as? Bool ?? false
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let window = self.anchorView?.window else {
                    result(nil)
                    return
                }
                window.ignoresMouseEvents = ignore
                result(nil)
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

/// 经由 [FlutterPluginRegistrar] 注册，与 CocoaPods/Flutter 生成的插件共用同一 [FlutterBinaryMessenger]，避免 hand-rolled `engine.binaryMessenger` 与 Dart isolate 不一致。
final class YeahMusicNativePlugin: NSObject, FlutterPlugin {
    static func register(with registrar: FlutterPluginRegistrar) {
        NSLog("YeahMusicNativePlugin.register messenger registered")
        YeahMusicMethodChannels.registerAll(messenger: registrar.messenger)
    }
}
