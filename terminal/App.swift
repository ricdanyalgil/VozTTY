import AppKit
import WebKit

@MainActor
final class TerminalWindow: NSObject, WKScriptMessageHandler, WKNavigationDelegate, NSWindowDelegate {
    let window: NSWindow
    let web: WKWebView
    let shell = ShellSession()
    let dictation = TerminalDictation()
    let status = NSTextField(labelWithString: "Ready · your voice stays on this Mac")
    let microphone = NSButton()
    let cancel = NSButton()
    let language = NSPopUpButton()
    private var launched = false
    private var allowClose = false
    private var recoveredTranscripts: [NSWindow] = []
    var didLoad: (() -> Void)?
    var inserted: ((String) -> Void)?
    var inputReceived: ((String) -> Void)?

    override init() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        web = WKWebView(frame: .zero, configuration: config)
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1120, height: 720), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        super.init()
        window.title = "VozTTY"
        window.minSize = NSSize(width: 620, height: 380)
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = NSColor(srgbRed: 17/255, green: 27/255, blue: 34/255, alpha: 1)
        web.navigationDelegate = self
        web.configuration.userContentController.add(self, name: "terminal")
        let brand = NSTextField(labelWithString: "VozTTY")
        brand.font = .systemFont(ofSize: 17, weight: .semibold)
        status.font = .systemFont(ofSize: 12)
        status.textColor = .secondaryLabelColor
        status.lineBreakMode = .byTruncatingTail
        status.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        brand.setContentCompressionResistancePriority(.required, for: .horizontal)
        language.addItems(withTitles: ["pt-BR", "pt-PT", "en-US"])
        language.selectItem(withTitle: UserDefaults.standard.string(forKey: "language") ?? "pt-BR")
        language.setAccessibilityLabel("Dictation language")
        language.target = self
        language.action = #selector(changeLanguage)
        microphone.title = "Dictate"
        microphone.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "Start dictation")
        microphone.imagePosition = .imageLeading
        microphone.bezelStyle = .rounded
        microphone.contentTintColor = NSColor(srgbRed: 216/255, green: 252/255, blue: 135/255, alpha: 1)
        microphone.setContentCompressionResistancePriority(.required, for: .horizontal)
        microphone.target = self
        microphone.action = #selector(toggleVoice)
        microphone.toolTip = "Speak into this prompt. Control + Option + V."
        cancel.title = "Cancel"
        cancel.bezelStyle = .rounded
        cancel.target = self
        cancel.action = #selector(cancelVoice)
        cancel.isHidden = true
        let spacer = NSView()
        let bar = NSStackView(views: [brand, status, spacer, language, cancel, microphone])
        bar.orientation = .horizontal
        bar.spacing = 14
        bar.edgeInsets = NSEdgeInsets(top: 12, left: 20, bottom: 12, right: 16)
        let footer = NSTextField(labelWithString: "Control + Option + V to dictate   ·   Esc to cancel   ·   Review before sending")
        footer.font = .systemFont(ofSize: 11)
        footer.textColor = .secondaryLabelColor
        let root = NSView()
        window.contentView = root
        for view in [bar, web, footer] { view.translatesAutoresizingMaskIntoConstraints = false; root.addSubview(view) }
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: root.topAnchor), bar.leadingAnchor.constraint(equalTo: root.leadingAnchor), bar.trailingAnchor.constraint(equalTo: root.trailingAnchor), bar.heightAnchor.constraint(equalToConstant: 58),
            web.topAnchor.constraint(equalTo: bar.bottomAnchor), web.leadingAnchor.constraint(equalTo: root.leadingAnchor), web.trailingAnchor.constraint(equalTo: root.trailingAnchor), web.bottomAnchor.constraint(equalTo: footer.topAnchor, constant: -8),
            footer.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 20), footer.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -10)
        ])
        shell.output = { [weak self] data in self?.js("window.voz.write(\(Self.json(data.base64EncodedString())))") }
        shell.ended = { [weak self] in
            guard let self else { return }
            self.dictation.cancel()
            self.status.stringValue = "Session ended · close this window when ready"
            self.microphone.isEnabled = false
            self.js("window.voz.write(\(Self.json(Data("\r\n[Session ended]\r\n".utf8).base64EncodedString())))")
        }
        dictation.changed = { [weak self] state in self?.voiceState(state) }
        dictation.completed = { [weak self] text in
            guard let self else { return }
            guard self.shell.pid > 0 else { self.recover(text, reason: "Session ended. Your dictation is preserved here."); return }
            self.web.evaluateJavaScript("window.voz.insert(\(Self.json(text)))") { [weak self] _, error in
                guard let self else { return }
                if let error { self.recover(text, reason: "Could not insert the transcript: \(error.localizedDescription)") }
                else { self.status.stringValue = "Text inserted · review before sending"; self.inserted?(text) }
            }
        }
        dictation.failed = { [weak self] message in self?.error(message) }
        if let folder = Bundle.main.resourceURL?.appendingPathComponent("web") {
            web.loadFileURL(folder.appendingPathComponent("index.html"), allowingReadAccessTo: folder)
        }
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    static func json(_ value: String) -> String {
        String(data: try! JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed]), encoding: .utf8)!
    }
    func js(_ script: String) { web.evaluateJavaScript(script, completionHandler: nil) }
    func error(_ message: String) { status.stringValue = message; status.toolTip = message }

    private func recover(_ text: String, reason: String) {
        error(reason)
        let panel = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 680, height: 360), styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        panel.title = "Recovered dictation — review before closing"
        panel.isReleasedWhenClosed = false
        let scroll = NSScrollView(frame: panel.contentView!.bounds)
        scroll.autoresizingMask = [.width, .height]
        scroll.hasVerticalScroller = true
        let editor = NSTextView(frame: scroll.bounds)
        editor.autoresizingMask = [.width]
        editor.isVerticallyResizable = true
        editor.string = text
        editor.font = .systemFont(ofSize: 15)
        editor.textContainerInset = NSSize(width: 16, height: 16)
        scroll.documentView = editor
        panel.contentView = scroll
        recoveredTranscripts.append(panel)
        panel.center()
        panel.makeKeyAndOrderFront(nil)
    }

    @objc func toggleVoice() {
        if dictation.state == .recording { dictation.stop() }
        else if dictation.state == .idle, shell.pid > 0 { dictation.start(language: language.titleOfSelectedItem ?? "pt-BR") }
        window.makeFirstResponder(web)
        js("window.voz.focus()")
    }
    @objc func cancelVoice() { dictation.cancel(); window.makeFirstResponder(web) }
    @objc func changeLanguage() { UserDefaults.standard.set(language.titleOfSelectedItem, forKey: "language") }

    private func voiceState(_ state: TerminalDictation.State) {
        let active = state != .idle
        cancel.isHidden = !active
        language.isEnabled = !active
        microphone.isEnabled = (state == .idle || state == .recording) && shell.pid > 0
        microphone.contentTintColor = state == .recording ? .systemRed : NSColor(srgbRed: 216/255, green: 252/255, blue: 135/255, alpha: 1)
        microphone.title = state == .recording ? "Stop & insert" : "Dictate"
        microphone.image = NSImage(systemSymbolName: state == .recording ? "stop.fill" : "mic", accessibilityDescription: microphone.title)
        status.stringValue = switch state {
        case .idle: "Ready · your voice stays on this Mac"
        case .preparing: "Preparing microphone · authorize access if macOS asks"
        case .recording: "Recording · speak your whole thought"
        case .stopping: "Transcribing on your Mac…"
        }
        js("window.voz.state(\(active))")
    }

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.frameInfo.isMainFrame, let body = message.body as? [String: Any], let type = body["type"] as? String else { return }
        switch type {
        case "ready":
            guard !launched else { return }
            launched = true
            do {
                let args = CommandLine.arguments
                if let index = args.firstIndex(of: "--"), args.count > index + 1 {
                    try shell.start(executable: args[index + 1], arguments: Array(args.dropFirst(index + 2)), directory: FileManager.default.currentDirectoryPath)
                } else {
                    let cwd = FileManager.default.currentDirectoryPath
                    try shell.start(executable: "/bin/zsh", arguments: ["-l"], directory: cwd == "/" ? NSHomeDirectory() : cwd)
                }
                if let columns = body["columns"] as? Int, let rows = body["rows"] as? Int { shell.resize(columns: columns, rows: rows) }
                voiceState(.idle)
                didLoad?()
            } catch { self.error("Could not start the terminal: \(error.localizedDescription)") }
        case "input": if let text = body["data"] as? String, text.utf8.count <= 1_048_576 { inputReceived?(text); shell.write(text) }
        case "resize": if let cols = body["columns"] as? Int, let rows = body["rows"] as? Int { shell.resize(columns: cols, rows: rows) }
        case "voice": toggleVoice()
        case "cancelVoice": cancelVoice()
        case "title": if let title = body["title"] as? String { window.title = title.isEmpty ? "VozTTY" : "VozTTY — \(title.prefix(100))" }
        default: break
        }
    }

    func webView(_ view: WKWebView, decidePolicyFor action: WKNavigationAction) async -> WKNavigationActionPolicy {
        let url = action.request.url
        let root = Bundle.main.resourceURL?.appendingPathComponent("web").standardizedFileURL.path ?? ""
        return url?.isFileURL == true && url!.standardizedFileURL.path.hasPrefix(root + "/") ? .allow : .cancel
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        if !allowClose && shell.pid > 0 {
            let alert = NSAlert()
            alert.messageText = "Close this terminal?"
            alert.informativeText = "Running programs will end and unsent prompt text will be lost."
            alert.addButton(withTitle: "Keep Open")
            alert.addButton(withTitle: "Close Terminal")
            guard alert.runModal() == .alertSecondButtonReturn else { return false }
        }
        allowClose = true
        dictation.cancel()
        shell.close()
        return true
    }
    func windowWillClose(_ notification: Notification) { NSApplication.shared.terminate(nil) }
    func closeForTest() { allowClose = true; window.performClose(nil) }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var terminal: TerminalWindow?
    func applicationDidFinishLaunching(_ notification: Notification) {
        let main = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit VozTTY", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        main.addItem(appItem)
        let editItem = NSMenuItem(title: "Edit", action: nil, keyEquivalent: "")
        let edit = NSMenu(title: "Edit")
        for (title, action, key) in [("Copy", "copy:", "c"), ("Paste", "paste:", "v"), ("Select All", "selectAll:", "a")] {
            edit.addItem(withTitle: title, action: Selector(action), keyEquivalent: key)
        }
        editItem.submenu = edit
        main.addItem(editItem)
        NSApplication.shared.mainMenu = main
        terminal = TerminalWindow()
        NSApplication.shared.activate(ignoringOtherApps: true)
        #if VOZ_TEST
        if let terminal { Task { await terminal.runIntegrationTest() } }
        #endif
    }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let terminal else { return .terminateNow }
        return terminal.windowShouldClose(terminal.window) ? .terminateNow : .terminateCancel
    }
}
