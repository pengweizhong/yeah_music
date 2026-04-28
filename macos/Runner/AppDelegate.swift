import Cocoa
import FlutterMacOS
import Carbon

@main
class AppDelegate: FlutterAppDelegate {
    private static let oauthRedirectScheme = "com.pengwz.yeahmusic"
    private static let flutterAppAuthPluginKey = "FlutterAppauthPlugin"

    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }

    /// 浏览器 / ASWebAuthenticationSession 完成 OAuth 后，系统通过 `application:openURLs:` 把自定义 scheme 交给应用。
    /// 直接调用 `flutter_appauth` 的 `handleGetURLEvent:`，比依赖 `dispatchRawAppleEvent` 更可靠。
    override func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            if url.scheme?.caseInsensitiveCompare(Self.oauthRedirectScheme) == .orderedSame {
                NSLog("YeahMusic: openURLs oauth redirect \(url.absoluteString)")
                if !yeahMusicForwardOAuthRedirectAppleEvent(for: url) {
                    yeahMusicDispatchInternetGetUrlAppleEvent(for: url)
                }
            }
        }
        super.application(application, open: urls)
    }

    /// 主窗口 outlet 偶发为空时兜底查找引擎。**跳过**桌面歌词等无边框子窗口，避免拿到子引擎上错误的 `publish` 实例。
    private func yeahMusicPrimaryFlutterEngine() -> FlutterEngine? {
        if let vc = mainFlutterWindow?.contentViewController as? FlutterViewController {
            return vc.engine
        }
        if let vc = NSApp.mainWindow?.contentViewController as? FlutterViewController {
            return vc.engine
        }
        for window in NSApp.windows {
            guard !window.styleMask.contains(.borderless) else { continue }
            if let vc = window.contentViewController as? FlutterViewController {
                return vc.engine
            }
        }
        return nil
    }

    /// 将回调 URL 交给已注册的 `FlutterAppauthPlugin`（需在插件内 `publish:` 实例）。
    private func yeahMusicForwardOAuthRedirectAppleEvent(for url: URL) -> Bool {
        guard let engine = yeahMusicPrimaryFlutterEngine() else {
            NSLog("YeahMusic: oauth forward skipped — no FlutterViewController / engine")
            return false
        }
        guard let published = engine.valuePublished(byPlugin: Self.flutterAppAuthPluginKey) else {
            NSLog("YeahMusic: oauth forward skipped — FlutterAppauthPlugin not published yet")
            return false
        }
        if published is NSNull {
            NSLog("YeahMusic: oauth forward skipped — FlutterAppauthPlugin not published yet")
            return false
        }
        let plugin = published as NSObject
        let sel = NSSelectorFromString("handleGetURLEvent:withReplyEvent:")
        guard plugin.responds(to: sel) else {
            NSLog("YeahMusic: oauth forward skipped — plugin missing handleGetURLEvent:")
            return false
        }
        let event = NSAppleEventDescriptor(
            eventClass: AEEventClass(kInternetEventClass),
            eventID: AEEventID(kAEGetURL),
            targetDescriptor: nil,
            returnID: AEReturnID(kAutoGenerateReturnID),
            transactionID: AETransactionID(kAnyTransactionID)
        )
        event.setDescriptor(
            NSAppleEventDescriptor(string: url.absoluteString),
            forKeyword: AEKeyword(keyDirectObject)
        )
        let reply = NSAppleEventDescriptor.null()
        plugin.perform(sel, with: event, with: reply)
        return true
    }

    /// 兜底：把 URL 当作 `kAEGetURL` 再派发一次（部分环境下仍可能需要）。
    private func yeahMusicDispatchInternetGetUrlAppleEvent(for url: URL) {
        let event = NSAppleEventDescriptor(
            eventClass: AEEventClass(kInternetEventClass),
            eventID: AEEventID(kAEGetURL),
            targetDescriptor: nil,
            returnID: AEReturnID(kAutoGenerateReturnID),
            transactionID: AETransactionID(kAnyTransactionID)
        )
        event.setDescriptor(
            NSAppleEventDescriptor(string: url.absoluteString),
            forKeyword: AEKeyword(keyDirectObject)
        )
        guard let rawPtr = event.aeDesc else {
            NSLog("YeahMusic: NSAppleEventDescriptor.aeDesc is nil")
            return
        }
        var replyAe = AppleEvent()
        let nullRefCon = unsafeBitCast(0 as Int, to: UnsafeMutableRawPointer.self)
        let err = NSAppleEventManager.shared().dispatchRawAppleEvent(
            rawPtr,
            withRawReply: &replyAe,
            handlerRefCon: nullRefCon
        )
        if err != noErr {
            NSLog("YeahMusic: dispatchRawAppleEvent OSStatus \(err)")
        }
    }

    /// 其它框架有可能在启动后覆盖 `kAEGetURL` 的 handler；在首帧后再抢回一次（与 JVM/Swing 等问题同类）。
    private func yeahMusicReinstallFlutterAppAuthGetUrlHandler() {
        guard let engine = yeahMusicPrimaryFlutterEngine() else { return }
        guard let published = engine.valuePublished(byPlugin: Self.flutterAppAuthPluginKey),
              !(published is NSNull) else { return }
        let plugin = published as NSObject
        let sel = NSSelectorFromString("handleGetURLEvent:withReplyEvent:")
        guard plugin.responds(to: sel) else { return }
        NSAppleEventManager.shared().setEventHandler(
            plugin,
            andSelector: sel,
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
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

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.yeahMusicReinstallFlutterAppAuthGetUrlHandler()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.yeahMusicReinstallFlutterAppAuthGetUrlHandler()
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
