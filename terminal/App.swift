import AppKit
import WebKit

/// Accepts files dragged from Finder and hands their paths to the terminal; everything else keeps WebKit's behaviour.
final class DropWebView: WKWebView {
    var droppedFiles: (([String]) -> Void)?
    private func files(_ info: any NSDraggingInfo) -> [String] {
        (info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []).map(\.path)
    }
    override func draggingEntered(_ info: any NSDraggingInfo) -> NSDragOperation { files(info).isEmpty ? super.draggingEntered(info) : .copy }
    override func draggingUpdated(_ info: any NSDraggingInfo) -> NSDragOperation { files(info).isEmpty ? super.draggingUpdated(info) : .copy }
    override func prepareForDragOperation(_ info: any NSDraggingInfo) -> Bool { files(info).isEmpty ? super.prepareForDragOperation(info) : true }
    override func performDragOperation(_ info: any NSDraggingInfo) -> Bool {
        let paths = files(info)
        guard !paths.isEmpty else { return super.performDragOperation(info) }
        droppedFiles?(paths)
        return true
    }
    override func concludeDragOperation(_ info: (any NSDraggingInfo)?) { if let info, !files(info).isEmpty { return }; super.concludeDragOperation(info) }
}

@MainActor
final class TerminalWindow: NSObject, WKScriptMessageHandler, WKNavigationDelegate, NSWindowDelegate {
    let window: NSWindow
    let web: DropWebView
    let shell = ShellSession()
    let dictation = TerminalDictation()
    let status = NSTextField(labelWithString: "Speak instead of typing · ⌃⌥V to start")
    let microphone = NSButton()
    let language = NSPopUpButton()
    let you = NSTextField(labelWithString: "")
    let assistant = NSTextField(labelWithString: "")
    let shortcuts = NSTextField(labelWithString: "")
    private var launched = false
    private var allowClose = false
    private var recoveredTranscripts: [NSWindow] = []
    var didLoad: (() -> Void)?
    var inserted: ((String) -> Void)?
    var inputReceived: ((String) -> Void)?

    override init() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        web = DropWebView(frame: .zero, configuration: config)
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1120, height: 720), styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
        super.init()
        window.title = "VozTTY"
        window.minSize = NSSize(width: 620, height: 380)
        window.isReleasedWhenClosed = false
        window.delegate = self
        window.appearance = NSAppearance(named: .darkAqua)
        window.backgroundColor = .black
        window.titlebarAppearsTransparent = false
        window.titleVisibility = .visible
        web.underPageBackgroundColor = .black
        web.navigationDelegate = self
        web.configuration.userContentController.add(self, name: "terminal")
        let brand = NSTextField(labelWithString: "VozTTY")
        brand.font = .systemFont(ofSize: 15, weight: .semibold)
        status.font = .systemFont(ofSize: 11)
        status.textColor = .secondaryLabelColor
        status.lineBreakMode = .byTruncatingTail
        status.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        brand.setContentCompressionResistancePriority(.required, for: .horizontal)
        let savedLanguage = UserDefaults.standard.string(forKey: "language") ?? "pt-BR"
        for code in ["pt-BR", "pt-PT", "en-US"] {
            language.addItem(withTitle: code)
            language.lastItem?.representedObject = code
            if code == savedLanguage { language.select(language.lastItem) }
        }
        language.setAccessibilityLabel("Dictation language")
        language.target = self
        language.action = #selector(changeLanguage)
        microphone.image = NSImage(systemSymbolName: "mic", accessibilityDescription: nil)
        microphone.imagePosition = .imageLeading
        microphone.bezelStyle = .rounded
        microphone.contentTintColor = NSColor(srgbRed: 169/255, green: 210/255, blue: 1, alpha: 1)
        microphone.setContentCompressionResistancePriority(.required, for: .horizontal)
        microphone.target = self
        microphone.action = #selector(toggleVoice)
        let spacer = NSView()
        let identity = NSStackView(views: [brand, status])
        identity.orientation = .vertical
        identity.alignment = .leading
        identity.spacing = 3
        let bar = NSStackView(views: [identity, spacer, language, microphone])
        bar.orientation = .horizontal
        bar.spacing = 12
        bar.edgeInsets = NSEdgeInsets(top: 10, left: 24, bottom: 10, right: 24)
        you.textColor = NSColor(srgbRed: 169/255, green: 210/255, blue: 1, alpha: 1)
        assistant.textColor = .labelColor
        shortcuts.textColor = .secondaryLabelColor
        for label in [you, assistant, shortcuts] { label.font = .systemFont(ofSize: 11) }
        let footer = NSStackView(views: [you, assistant, NSView(), shortcuts])
        footer.orientation = .horizontal
        footer.spacing = 16
        let root = NSView()
        window.contentView = root
        for view in [bar, web, footer] { view.translatesAutoresizingMaskIntoConstraints = false; root.addSubview(view) }
        NSLayoutConstraint.activate([
            bar.topAnchor.constraint(equalTo: root.topAnchor), bar.leadingAnchor.constraint(equalTo: root.leadingAnchor), bar.trailingAnchor.constraint(equalTo: root.trailingAnchor), bar.heightAnchor.constraint(equalToConstant: 64),
            web.topAnchor.constraint(equalTo: bar.bottomAnchor), web.leadingAnchor.constraint(equalTo: root.leadingAnchor), web.trailingAnchor.constraint(equalTo: root.trailingAnchor), web.bottomAnchor.constraint(equalTo: footer.topAnchor, constant: -10),
            footer.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 24), footer.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -24), footer.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -14)
        ])
        applyLanguage()
        web.registerForDraggedTypes(web.registeredDraggedTypes + [.fileURL])
        web.droppedFiles = { [weak self] paths in
            guard let self else { return }
            self.window.makeFirstResponder(self.web)
            self.js("window.voz.drop(\(Self.json(paths)))")
        }
        shell.output = { [weak self] data in self?.js("window.voz.write(\(Self.json(data.base64EncodedString())))") }
        shell.ended = { [weak self] in
            guard let self else { return }
            self.dictation.cancel()
            self.status.stringValue = self.tr("Session ended · close this window when ready", "Sessão encerrada · feche esta janela quando quiser")
            self.microphone.isEnabled = false
            self.js("window.voz.write(\(Self.json(Data("\r\n[Session ended]\r\n".utf8).base64EncodedString())))")
        }
        dictation.changed = { [weak self] state in self?.voiceState(state) }
        dictation.metered = { [weak self] level, seconds in self?.js("window.voz.meter(\(level), \(seconds))") }
        dictation.completed = { [weak self] text in
            guard let self else { return }
            guard self.shell.pid > 0 else { self.recover(text, reason: self.tr("Session ended. Your dictation is preserved here.", "Sessão encerrada. Seu ditado ficou guardado aqui.")); return }
            self.web.evaluateJavaScript("window.voz.insert(\(Self.json(text)))") { [weak self] _, error in
                guard let self else { return }
                if let error { self.recover(text, reason: self.tr("Could not insert the transcript: ", "Não foi possível inserir o texto: ") + error.localizedDescription) }
                else { self.status.stringValue = self.tr("Text inserted · review before pressing Enter", "Texto inserido · revise antes de apertar Enter"); self.inserted?(text) }
            }
        }
        dictation.failed = { [weak self] message in self?.error(message) }
        if let folder = Bundle.main.resourceURL?.appendingPathComponent("web") {
            web.loadFileURL(folder.appendingPathComponent("index.html"), allowingReadAccessTo: folder)
        }
        window.center()
        window.makeKeyAndOrderFront(nil)
    }

    static func json(_ value: Any) -> String {
        String(data: try! JSONSerialization.data(withJSONObject: value, options: [.fragmentsAllowed]), encoding: .utf8)!
    }
    func js(_ script: String) { web.evaluateJavaScript(script, completionHandler: nil) }
    func error(_ message: String) { status.stringValue = message; status.toolTip = message }

    private func recover(_ text: String, reason: String) {
        error(reason)
        let panel = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 680, height: 360), styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        panel.title = tr("Recovered dictation — review before closing", "Ditado recuperado — revise antes de fechar")
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
        if dictation.state == .recording || dictation.state == .paused { dictation.stop() }
        else if dictation.state == .idle, shell.pid > 0 { dictation.start(language: languageCode) }
        window.makeFirstResponder(web)
        js("window.voz.focus()")
    }
    @objc func cancelVoice() { dictation.cancel(); window.makeFirstResponder(web) }
    @objc func changeLanguage() { UserDefaults.standard.set(languageCode, forKey: "language"); applyLanguage() }

    var languageCode: String { language.selectedItem?.representedObject as? String ?? "pt-BR" }
    /// The interface follows the language chosen for dictation.
    func tr(_ en: String, _ pt: String) -> String { languageCode.hasPrefix("pt") ? pt : en }
    private func applyLanguage() {
        let names = ["pt-BR": tr("Portuguese (Brazil)", "Português (Brasil)"), "pt-PT": tr("Portuguese (Portugal)", "Português (Portugal)"), "en-US": tr("English (US)", "Inglês (EUA)")]
        for item in language.itemArray { item.title = names[item.representedObject as? String ?? ""] ?? item.title }
        language.toolTip = tr("Choose the language you will speak. Recognition runs on your Mac.", "Escolha o idioma em que vai falar. O reconhecimento roda no seu Mac.")
        microphone.title = tr("Dictate", "Ditar")
        microphone.toolTip = tr("Start voice dictation (Control + Option + V). Your text stays editable.", "Começar a ditar (Control + Option + V). O texto continua editável.")
        you.stringValue = tr("› Your input", "› Sua entrada")
        assistant.stringValue = tr("Terminal output", "Saída do terminal")
        shortcuts.stringValue = tr("⌃⌥V Voice   ·   Esc Cancel   ·   Drop files to attach", "⌃⌥V Voz   ·   Esc Cancelar   ·   Arraste arquivos para anexar")
        voiceState(dictation.state)
    }

    private func voiceState(_ state: TerminalDictation.State) {
        // While dictating, the controls live only in the voice line inside the terminal.
        let active = state != .idle
        language.isHidden = active
        microphone.isHidden = active
        microphone.isEnabled = shell.pid > 0
        status.stringValue = switch state {
        case .idle: tr("Speak instead of typing · ⌃⌥V to start", "Fale em vez de digitar · ⌃⌥V para começar")
        case .preparing: tr("Preparing microphone · authorize access if macOS asks", "Preparando o microfone · autorize se o macOS pedir")
        case .recording: tr("Listening · click Stop & insert when you are done", "Ouvindo · clique em Parar e inserir quando terminar")
        case .pausing: tr("Pausing microphone…", "Pausando o microfone…")
        case .paused: tr("Paused · your recording is preserved", "Pausado · sua gravação está preservada")
        case .resuming: tr("Resuming microphone…", "Retomando o microfone…")
        case .stopping: tr("Transcribing on your Mac…", "Transcrevendo no seu Mac…")
        }
        js("window.voz.state(\(Self.json(state.rawValue)), \(Self.json(languageCode)))")
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
        case "pauseVoice": dictation.togglePause()
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
            alert.messageText = tr("Close this terminal?", "Fechar este terminal?")
            alert.informativeText = tr("Running programs will end and unsent prompt text will be lost.", "Os programas em execução vão terminar e o texto não enviado será perdido.")
            alert.addButton(withTitle: tr("Keep Open", "Manter aberto"))
            alert.addButton(withTitle: tr("Close Terminal", "Fechar terminal"))
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
        let vocabularyItem = appMenu.addItem(withTitle: "Edit Vocabulary…", action: #selector(editVocabulary), keyEquivalent: ",")
        vocabularyItem.target = self
        let controlItem = appMenu.addItem(withTitle: pt ? "Permitir controle do computador…" : "Allow Computer Control…", action: #selector(allowComputerControl), keyEquivalent: "")
        controlItem.target = self
        appMenu.addItem(.separator())
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
    private var pt: Bool { (UserDefaults.standard.string(forKey: "language") ?? "pt-BR").hasPrefix("pt") }

    /// Programs started in this terminal inherit its macOS privacy grants, so agent CLIs can drive the mouse,
    /// keyboard and screen once VozTTY itself is allowed. Ad hoc builds lose the grant on every rebuild.
    @objc func allowComputerControl() {
        let input = AXIsProcessTrustedWithOptions(["AXTrustedCheckOptionPrompt": true] as CFDictionary)
        let screen = CGPreflightScreenCaptureAccess() || CGRequestScreenCaptureAccess()
        let alert = NSAlert()
        let state = { (ok: Bool) in ok ? (self.pt ? "permitido" : "allowed") : (self.pt ? "falta permitir" : "not allowed yet") }
        alert.messageText = input && screen
            ? (pt ? "O VozTTY já pode controlar o computador" : "VozTTY can control this Mac")
            : (pt ? "Permita o VozTTY nos Ajustes do Sistema" : "Allow VozTTY in System Settings")
        alert.informativeText = (pt
            ? "Mouse e teclado (Acessibilidade): \(state(input))\nVer a tela (Gravação de Tela): \(state(screen))\n\nO que rodar neste terminal passa a poder usar o mouse, o teclado e a tela. Depois de permitir, feche e abra o VozTTY. AppleScript pede autorização na primeira vez que for usado."
            : "Mouse and keyboard (Accessibility): \(state(input))\nScreen (Screen Recording): \(state(screen))\n\nPrograms run in this terminal can then use the mouse, keyboard and screen. Reopen VozTTY after allowing. AppleScript asks the first time it is used.")
        alert.addButton(withTitle: "OK")
        if !input || !screen { alert.addButton(withTitle: pt ? "Abrir Ajustes" : "Open Settings") }
        if alert.runModal() == .alertSecondButtonReturn {
            let pane = input ? "Privacy_ScreenCapture" : "Privacy_Accessibility"
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)")!)
        }
    }

    @objc func editVocabulary() {
        do {
            try Vocabulary.createFileIfNeeded()
            if !NSWorkspace.shared.open(Vocabulary.fileURL) {
                throw NSError(domain: "VozTTY.Vocabulary", code: 2, userInfo: [NSLocalizedDescriptionKey: "Could not open vocabulary.txt in your text editor."])
            }
        } catch {
            NSAlert(error: error).runModal()
        }
    }
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard let terminal else { return .terminateNow }
        return terminal.windowShouldClose(terminal.window) ? .terminateNow : .terminateCancel
    }
}
