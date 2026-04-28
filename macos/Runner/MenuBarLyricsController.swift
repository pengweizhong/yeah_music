import Cocoa
import FlutterMacOS

/// 在菜单栏展示当前句歌词（紧凑版）。
/// - 宽度固定；过长单行尾部省略。
/// - **右键**歌词区域：当前曲目、播放控制、宽度、退出。
/// - 与同区域其它图标一样，可按 **⌘ + 拖拽**调换顺序。
final class MenuBarLyricsController: NSObject {
    static let shared = MenuBarLyricsController()

    private static let defaultsWidthKey = "yeah_music.menu_bar_lyrics.width"

    private static let minWidthPts: CGFloat = 90
    private static let maxWidthPts: CGFloat = 300
    private static let widthStepPts: CGFloat = 15

    /// 首次或未写入 UserDefaults 时的默认宽度（pt），落在预设阶梯上
    private static let defaultWidthPts: CGFloat = 210

    /// 右键「宽度」子菜单：90…300，每隔 15 pt 一档
    private static let widthPresetPts: [CGFloat] = Array(
        stride(from: Int(minWidthPts), through: Int(maxWidthPts), by: Int(widthStepPts))
    ).map { CGFloat($0) }

    private var statusItem: NSStatusItem?
    private var lastDisplayedText = ""
    private var rightMouseMonitor: Any?

    private weak var flutterMessenger: FlutterBinaryMessenger?

    /// 右键菜单展示（由 Flutter [setMenuBarState] 同步）
    private var menuIsPlaying = false
    private var menuTrackTitle = ""
    private var menuTrackArtist = ""
    private var menuPlayPauseTitle = "Play"
    private var menuPreviousTitle = "Previous"
    private var menuNextTitle = "Next"

    private override init() {
        super.init()
    }

    /// 供 MethodChannel 注册时绑定，便于菜单动作回调 Flutter。
    func attachFlutterMessenger(_ messenger: FlutterBinaryMessenger) {
        flutterMessenger = messenger
    }

    func setVisible(_ visible: Bool) {
        if visible {
            ensureStatusItem()
            statusItem?.isVisible = true
        } else {
            statusItem?.isVisible = false
        }
    }

    func setText(_ text: String) {
        ensureStatusItem()
        lastDisplayedText = text

        guard let item = statusItem, let button = item.button else { return }

        button.imagePosition = .noImage
        item.length = Self.storedFixedWidthPts()

        refreshButtonTitle(button: button, text: text)
    }

    func setMenuBarState(
        isPlaying: Bool,
        trackTitle: String,
        trackArtist: String,
        playPauseTitle: String,
        previousTitle: String,
        nextTitle: String
    ) {
        menuIsPlaying = isPlaying
        menuTrackTitle = trackTitle
        menuTrackArtist = trackArtist
        menuPlayPauseTitle = playPauseTitle
        menuPreviousTitle = previousTitle
        menuNextTitle = nextTitle
    }

    // MARK: - Width persistence

    private static func storedFixedWidthPts() -> CGFloat {
        if UserDefaults.standard.object(forKey: defaultsWidthKey) == nil {
            return defaultWidthPts
        }

        let raw = UserDefaults.standard.double(forKey: defaultsWidthKey)

        guard raw > 0 else { return defaultWidthPts }

        var w = CGFloat(raw)

        guard w >= minWidthPts, w <= maxWidthPts else { return defaultWidthPts }

        // 与预设阶梯对齐（90…300，步长 15），旧存盘如 212 会写入为 210
        let steps = (w - minWidthPts) / widthStepPts
        let snapped = minWidthPts + (CGFloat(round(Double(steps))) * widthStepPts)
        w = min(maxWidthPts, max(minWidthPts, snapped))

        if abs(w - CGFloat(raw)) > 0.51 {
            UserDefaults.standard.set(Double(w), forKey: defaultsWidthKey)
        }

        return w
    }

    private func applyFixedWidthPts(_ pts: CGFloat) {
        let clamped = min(Self.maxWidthPts, max(Self.minWidthPts, pts))

        UserDefaults.standard.set(Double(clamped), forKey: Self.defaultsWidthKey)

        statusItem?.length = clamped

        setText(lastDisplayedText)
    }

    private func refreshButtonTitle(button: NSStatusBarButton, text: String) {
        let paragraph = NSMutableParagraphStyle()
        paragraph.alignment = .center
        paragraph.lineBreakMode = .byTruncatingTail

        let attrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 11, weight: .medium),
            .foregroundColor: NSColor.labelColor,
            .paragraphStyle: paragraph,
        ]

        button.attributedTitle = NSAttributedString(string: text, attributes: attrs)
        button.toolTip = text

        if let cell = button.cell as? NSButtonCell {
            cell.lineBreakMode = .byTruncatingTail
            cell.alignment = .center
        }
    }

    /// 右键菜单行内 SF Symbol：与菜单字体对齐，模板色适配浅色/深色。
    private func contextMenuSymbol(_ systemName: String) -> NSImage? {
        guard #available(macOS 11.0, *) else { return nil }
        guard let base = NSImage(systemSymbolName: systemName, accessibilityDescription: nil) else {
            return nil
        }
        let cfg = NSImage.SymbolConfiguration(pointSize: 13, weight: .medium, scale: .medium)
        let img = base.withSymbolConfiguration(cfg) ?? base
        img.isTemplate = true
        return img
    }

    // MARK: - Flutter callbacks

    private func invokeFlutterMenuAction(_ method: String) {
        guard let messenger = flutterMessenger else { return }
        let ch = FlutterMethodChannel(name: "yeah_music/menu_bar_lyrics", binaryMessenger: messenger)
        ch.invokeMethod(method, arguments: nil) { _ in }
    }

    // MARK: - Context menu

    private func buildContextMenu() -> NSMenu {
        let menu = NSMenu()

        // 1. 当前曲目「歌名 – 歌手」（只读）
        let nowPlaying = NSMenuItem(title: formatNowPlayingMenuTitle(), action: nil, keyEquivalent: "")
        nowPlaying.isEnabled = false
        menu.addItem(nowPlaying)

        menu.addItem(.separator())

        // 2. 播放控制（顺序：播放/暂停 → 上一曲 → 下一曲）
        let pp = NSMenuItem(
            title: menuPlayPauseTitle,
            action: #selector(menuPlayPause(_:)),
            keyEquivalent: ""
        )
        pp.target = self
        pp.image = contextMenuSymbol(menuIsPlaying ? "pause.fill" : "play.fill")
        menu.addItem(pp)

        let prev = NSMenuItem(
            title: menuPreviousTitle,
            action: #selector(menuPrevious(_:)),
            keyEquivalent: ""
        )
        prev.target = self
        // `backward.end.fill` / `forward.end.fill`：跳至上一首/下一首（与系统媒体控制一致）；
        // 避免 `backward.fill` / `forward.fill` 被理解成长按快退/快进。
        prev.image = contextMenuSymbol("backward.end.fill")
        menu.addItem(prev)

        let next = NSMenuItem(
            title: menuNextTitle,
            action: #selector(menuNext(_:)),
            keyEquivalent: ""
        )
        next.target = self
        next.image = contextMenuSymbol("forward.end.fill")
        menu.addItem(next)

        menu.addItem(.separator())

        // 3. 宽度子菜单
        let widthItem = NSMenuItem(title: "歌词宽度", action: nil, keyEquivalent: "")
        let widthSubmenu = NSMenu()

        let current = Self.storedFixedWidthPts()

        for w in Self.widthPresetPts {
            let isCurrent = abs(w - current) < 0.51
            let title = formatWidthPresetTitle(points: w)

            let mi = NSMenuItem(
                title: title,
                action: #selector(menuWidthChosen(_:)),
                keyEquivalent: ""
            )
            mi.target = self
            mi.tag = Self.tagFromWidthPts(w)
            mi.state = isCurrent ? .on : .off

            widthSubmenu.addItem(mi)
        }

        widthItem.submenu = widthSubmenu
        // 左右双箭头：表示歌词区域水平宽度，与「横向占位」语义一致。
        widthItem.image = contextMenuSymbol("arrow.left.and.right")
        menu.addItem(widthItem)

        menu.addItem(.separator())

        let quitTitle = appDisplayNameForMenu()
        let quit = NSMenuItem(
            title: "退出 \(quitTitle)",
            action: #selector(quitApplication),
            keyEquivalent: ""
        )
        quit.target = self
        quit.image = contextMenuSymbol("power")
        menu.addItem(quit)

        return menu
    }

    private func formatNowPlayingMenuTitle() -> String {
        let t = menuTrackTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let a = menuTrackArtist.trimmingCharacters(in: .whitespacesAndNewlines)

        if t.isEmpty, a.isEmpty {
            return "Yeah Music"
        }
        if a.isEmpty {
            return t
        }
        if t.isEmpty {
            return a
        }
        return "\(t) – \(a)"
    }

    private func formatWidthPresetTitle(points: CGFloat) -> String {
        "\(Int(points.rounded())) pt"
    }

    private static func tagFromWidthPts(_ w: CGFloat) -> Int {
        Int(w.rounded())
    }

    private static func widthPtsFromTag(_ tag: Int) -> CGFloat {
        CGFloat(tag)
    }

    @objc private func menuPlayPause(_ sender: Any?) {
        invokeFlutterMenuAction("menuPlayPause")
    }

    @objc private func menuPrevious(_ sender: Any?) {
        invokeFlutterMenuAction("menuPrevious")
    }

    @objc private func menuNext(_ sender: Any?) {
        invokeFlutterMenuAction("menuNext")
    }

    @objc private func menuWidthChosen(_ sender: Any?) {
        guard let mi = sender as? NSMenuItem else { return }

        let pts = Self.widthPtsFromTag(mi.tag)

        applyFixedWidthPts(pts)
    }

    @objc private func quitApplication() {
        NSApplication.shared.terminate(nil)
    }

    private func appDisplayNameForMenu() -> String {
        if let s = Bundle.main.localizedInfoDictionary?["CFBundleDisplayName"] as? String, !s.isEmpty {
            return s
        }
        if let s = Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String, !s.isEmpty {
            return s
        }
        if let s = Bundle.main.infoDictionary?[kCFBundleNameKey as String] as? String, !s.isEmpty {
            return s
        }

        return "Yeah Music"
    }

    // MARK: - Status item lifecycle

    private func ensureStatusItem() {
        if statusItem != nil {
            attachRightMouseMonitorIfNeeded()
            return
        }

        let w = Self.storedFixedWidthPts()
        let item = NSStatusBar.system.statusItem(withLength: w)

        item.autosaveName = "yeah_music_menu_bar_lyrics"
        item.isVisible = true

        guard let button = item.button else {
            statusItem = item
            return
        }

        button.imagePosition = .noImage
        statusItem = item

        attachRightMouseMonitorIfNeeded()
    }

    private func attachRightMouseMonitorIfNeeded() {
        if rightMouseMonitor != nil {
            return
        }

        rightMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            guard let self else { return event }
            guard let button = self.statusItem?.button,
                  event.window === button.window else {
                return event
            }

            let ptInBtn = button.convert(event.locationInWindow, from: nil)

            guard button.bounds.contains(ptInBtn) else {
                return event
            }

            let menu = self.buildContextMenu()

            NSMenu.popUpContextMenu(menu, with: event, for: button)

            return nil
        }
    }
}
