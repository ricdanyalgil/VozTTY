import Foundation
import AppKit

@MainActor
extension TerminalWindow {
    func testUntil(_ message: String, seconds: Double = 30, _ check: () async throws -> Bool) async throws {
        let end = Date().addingTimeInterval(seconds)
        while Date() < end {
            if try await check() { return }
            try await Task.sleep(for: .milliseconds(100))
        }
        throw NSError(domain: "VozTTYTest", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }

    func screenText() async throws -> String {
        (try await web.evaluateJavaScript("window.voz.screen()")) as? String ?? ""
    }

    func runIntegrationTest() async {
        let env = ProcessInfo.processInfo.environment
        guard let destination = env["VOZ_TEST_RESULT"] else { return }
        let mode = env["VOZ_TEST_MODE"] ?? "inspect"
        var result: [String: Any] = ["passed": false, "mode": mode, "terminal": "VozTTY native", "automaticEnter": false]
        var inputs: [String] = []
        inputReceived = { inputs.append($0) }
        func save() { try? JSONSerialization.data(withJSONObject: result, options: [.prettyPrinted, .sortedKeys]).write(to: URL(fileURLWithPath: destination)) }
        save()
        do {
            try await testUntil("The terminal frontend did not start.") { self.shell.pid > 0 }
            try await Task.sleep(for: .seconds(6))
            var before = try await screenText()
            if let path = env["VOZ_TEST_SCREEN"] { try before.write(toFile: path, atomically: true, encoding: .utf8) }
            result["frontendReady"] = true
            result["childPID"] = shell.pid
            if mode == "inspect" { result["passed"] = true; save(); closeForTest(); return }
            if env["VOZ_TEST_TRUST_DISPOSABLE"] == "1", before.contains("Accessing workspace:"), before.contains("Yes, I trust this folder") {
                let cwd = FileManager.default.currentDirectoryPath
                let entries = try FileManager.default.contentsOfDirectory(atPath: cwd)
                guard (cwd.hasPrefix("/tmp/voztty-workspace.") || cwd.hasPrefix("/private/tmp/voztty-workspace.")), entries.isEmpty else {
                    throw NSError(domain: "VozTTYTest", code: 5, userInfo: [NSLocalizedDescriptionKey: "Refusing to trust a non-empty or non-test workspace."])
                }
                shell.write("\u{1b}[B\r")
                result["disposableWorkspaceSetup"] = true
                try await Task.sleep(for: .seconds(5))
                before = try await screenText()
            }
            if before.contains("Do you trust the files in this folder?"), before.contains("Don't trust") {
                // Stay untrusted: testing a draft needs no project hooks, skills or file access.
                shell.write("\u{1b}[B\u{1b}[B\r")
                result["untrustedWorkspaceUsed"] = true
                try await Task.sleep(for: .seconds(6))
                before = try await screenText()
            }
            if let path = env["VOZ_TEST_SCREEN"] { try before.write(toFile: path, atomically: true, encoding: .utf8) }
            if before.contains("Update available"), before.contains("esc skip") {
                shell.write("\u{1b}")
                try await Task.sleep(for: .seconds(3))
                before = try await screenText()
            }
            guard let ready = env["VOZ_TEST_READY"], before.range(of: ready, options: .regularExpression) != nil else {
                throw NSError(domain: "VozTTYTest", code: 2, userInfo: [NSLocalizedDescriptionKey: "CLI has not reached the expected input prompt. See the local screen capture."])
            }
            let prefix = "VozTTY test: "
            try await web.evaluateJavaScript("window.voz.insert(\(Self.json(prefix)))")
            try await Task.sleep(for: .milliseconds(300))
            let countBefore = inputs.count
            let start = Date()
            var transcript = ""
            if mode == "long-microphone" {
                guard let phrasePath = env["VOZ_TEST_PHRASE"], let outputPath = env["VOZ_TEST_TRANSCRIPT"] else { throw CocoaError(.fileNoSuchFile) }
                let phrase = try String(contentsOfFile: phrasePath, encoding: .utf8)
                var delivered: String?
                inserted = { delivered = $0 }
                toggleVoice()
                try await testUntil("Microphone did not start. Check the macOS permission prompt.", seconds: 90) { self.dictation.state == .recording }
                result["microphoneReady"] = true; save()
                try await Task.sleep(for: .seconds(2))
                let voice = Process()
                voice.executableURL = URL(fileURLWithPath: "/usr/bin/say")
                voice.arguments = ["-v", "Luciana (Português (Brasil))", "-r", "170", phrase]
                voice.standardOutput = FileHandle.nullDevice
                voice.standardError = FileHandle.nullDevice
                try voice.run()
                try await testUntil("Test phrase playback timed out.", seconds: 180) { !voice.isRunning }
                guard voice.terminationStatus == 0 else { throw CocoaError(.executableRuntimeMismatch) }
                try await Task.sleep(for: .milliseconds(800))
                result["recordingSeconds"] = Date().timeIntervalSince(start)
                toggleVoice()
                try await testUntil("Long transcript did not arrive.", seconds: 65) { delivered != nil }
                result["audioSeconds"] = dictation.audioSeconds
                result["captureSeconds"] = dictation.captureSeconds
                transcript = delivered!
                let sourceWords = phrase.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber })
                let outputWords = transcript.lowercased().split(whereSeparator: { !$0.isLetter && !$0.isNumber })
                result["referenceWords"] = sourceWords.count
                result["openingPreserved"] = Array(sourceWords.prefix(6)) == Array(outputWords.prefix(6))
                result["closingPreserved"] = Array(sourceWords.suffix(6)) == Array(outputWords.suffix(6))
                try transcript.write(toFile: outputPath, atomically: true, encoding: .utf8)
            } else {
                guard let path = env["VOZ_TEST_TRANSCRIPT"] else { throw CocoaError(.fileNoSuchFile) }
                transcript = try String(contentsOfFile: path, encoding: .utf8)
                try await web.evaluateJavaScript("window.voz.insert(\(Self.json(transcript)))")
            }
            try await testUntil("Transcript did not reach the PTY.") { inputs.count > countBefore }
            try await Task.sleep(for: .seconds(3))
            let sent = inputs.dropFirst(countBefore).joined().replacingOccurrences(of: "\u{1b}[200~", with: "").replacingOccurrences(of: "\u{1b}[201~", with: "")
            guard sent == transcript, !sent.contains(where: { $0 == "\r" || $0 == "\n" || $0 == "\u{1b}" }) else {
                throw NSError(domain: "VozTTYTest", code: 3, userInfo: [NSLocalizedDescriptionKey: "PTY input differs from the transcript or includes a terminal control."])
            }
            let screen = try await screenText()
            if let path = env["VOZ_TEST_SCREEN"] { try screen.write(toFile: path, atomically: true, encoding: .utf8) }
            let compact = screen.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
            let beginning = transcript.split(separator: " ").prefix(5).joined(separator: " ")
            let ending = transcript.split(separator: " ").suffix(5).joined(separator: " ")
            result["prefixVisible"] = compact.contains(prefix.trimmingCharacters(in: .whitespaces))
            result["beginningVisible"] = compact.contains(beginning)
            result["endingVisible"] = compact.contains(ending)
            result["pasteIndicator"] = screen.range(of: "(?i)pasted|paste|colad", options: .regularExpression) != nil
            result["characters"] = transcript.count
            result["words"] = transcript.split(whereSeparator: { $0.isWhitespace }).count
            result["transportMatches"] = true
            result["childAliveAfterDraft"] = shell.pid > 0
            result["automaticEnter"] = false
            guard shell.pid > 0, (result["prefixVisible"] as? Bool == true), (result["endingVisible"] as? Bool == true || result["pasteIndicator"] as? Bool == true) else {
                throw NSError(domain: "VozTTYTest", code: 4, userInfo: [NSLocalizedDescriptionKey: "The CLI draft is not visibly confirmed. Inspect the local screen capture."])
            }
            if mode == "cli" {
                window.makeKeyAndOrderFront(nil)
                NSApplication.shared.activate(ignoringOtherApps: true)
                try await testUntil("No prompt accent was painted for the CLI composer.") {
                    (try await self.web.evaluateJavaScript("accents.length")) as? Int ?? 0 > 0
                }
                result["accentedRows"] = try await web.evaluateJavaScript("accents.length")
                let selectionPreserved = try await web.evaluateJavaScript("(() => { const row = accents[0].marker.line; const text = term.buffer.active.getLine(row).translateToString(true); term.select(0, row, term.cols); const selected = term.getSelection(); term.clearSelection(); return selected.trimEnd() === text.trimEnd(); })()") as? Bool == true
                result["selectionPreserved"] = selectionPreserved
                guard selectionPreserved else { throw NSError(domain: "VozTTYTest", code: 6, userInfo: [NSLocalizedDescriptionKey: "Accented text selection changed the terminal text."]) }
            }
            result["insertionPassed"] = true
            result["passed"] = mode != "long-microphone" || (result["openingPreserved"] as? Bool == true && result["closingPreserved"] as? Bool == true)
        } catch { result["error"] = error.localizedDescription }
        save()
        if env["VOZ_TEST_KEEP_OPEN"] != "1" { closeForTest() }
    }
}
