import Foundation
import Darwin

func promptText(_ text: String) -> String {
    let safe = text.unicodeScalars.filter { scalar in
        CharacterSet.whitespacesAndNewlines.contains(scalar) || !CharacterSet.controlCharacters.contains(scalar)
    }
    return String(String.UnicodeScalarView(safe)).split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
}

@MainActor
final class TerminalDictation {
    enum State: String { case idle, preparing, recording, pausing, paused, resuming, stopping }
    private(set) var state: State = .idle
    private(set) var audioSeconds: Double?
    private(set) var captureSeconds: Double?
    private var process: Process?
    private var input: Pipe?
    private var buffer = Data()
    private var timeout: Task<Void, Never>?
    var changed: ((State) -> Void)?
    var completed: ((String) -> Void)?
    var failed: ((String) -> Void)?
    var metered: ((Double, Double) -> Void)?

    func start(language: String) {
        guard state == .idle else { return }
        guard ["pt-BR", "pt-PT", "en-US"].contains(language), let helper = Bundle.main.resourceURL?.appendingPathComponent("VozEngine.app/Contents/MacOS/VozEngine") else { return }
        let child = Process()
        let stdin = Pipe(), stdout = Pipe()
        child.executableURL = helper
        child.arguments = ["--language", language, "--meter"]
        child.standardInput = stdin
        child.standardOutput = stdout
        child.standardError = FileHandle.nullDevice
        audioSeconds = nil
        captureSeconds = nil
        input = stdin
        process = child
        buffer.removeAll(keepingCapacity: true)
        update(.preparing)
        stdout.fileHandleForReading.readabilityHandler = { [weak self, weak child] file in
            var bytes = [UInt8](repeating: 0, count: 65536)
            let count = Darwin.read(file.fileDescriptor, &bytes, bytes.count)
            let data = count > 0 ? Data(bytes.prefix(count)) : Data()
            if data.isEmpty { file.readabilityHandler = nil }
            else { Task { @MainActor in
                guard let self, self.process === child else { return }
                self.read(data)
            } }
        }
        child.terminationHandler = { [weak self] child in
            Task { @MainActor in
                // Allow the last stdout event to drain before interpreting an exit as a failure.
                try? await Task.sleep(for: .milliseconds(200))
                guard let self, self.process === child else { return }
                self.fail("Recognition ended before returning text. Try again.")
            }
        }
        do { try child.run() }
        catch { fail("Could not open the microphone: \(error.localizedDescription)") }
    }

    func stop() {
        guard state == .recording || state == .paused else { return }
        update(.stopping)
        do { try input?.fileHandleForWriting.write(contentsOf: Data("stop\n".utf8)) }
        catch { fail("The microphone connection was interrupted."); return }
        timeout = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(60)) } catch { return }
            self?.fail("Transcription timed out. Nothing was inserted.")
        }
    }

    func togglePause() {
        guard state == .recording || state == .paused else { return }
        let command = state == .recording ? "pause" : "resume"
        update(state == .recording ? .pausing : .resuming)
        do { try input?.fileHandleForWriting.write(contentsOf: Data("\(command)\n".utf8)) }
        catch { fail("The microphone connection was interrupted."); return }
        timeout = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(10)) } catch { return }
            self?.fail("The microphone did not acknowledge \(command). Nothing was inserted.")
        }
    }

    private func read(_ data: Data) {
        buffer.append(data)
        guard buffer.count <= 1_048_576 else { fail("Recognition response is too large."); return }
        while let end = buffer.firstIndex(of: 10), process != nil {
            let line = buffer.prefix(upTo: end)
            buffer.removeSubrange(...end)
            guard let event = try? JSONSerialization.jsonObject(with: line) as? [String: String], let type = event["type"] else { fail("Invalid recognition response."); return }
            if type == "ready" && state == .preparing { update(.recording) }
            else if type == "level", [.recording, .pausing, .resuming, .stopping].contains(state),
                    let level = event["value"].flatMap(Double.init), level.isFinite, (0...1).contains(level),
                    let seconds = event["seconds"].flatMap(Double.init), seconds.isFinite, seconds >= 0 {
                metered?(level, seconds)
            }
            else if type == "paused" && state == .pausing { timeout?.cancel(); timeout = nil; update(.paused) }
            else if type == "resumed" && state == .resuming { timeout?.cancel(); timeout = nil; update(.recording) }
            else if type == "error", let message = event["message"] { fail(String(message.prefix(1000))) }
            else if type == "final", state == .stopping, let value = event["text"] {
                audioSeconds = event["audioSeconds"].flatMap(Double.init)
                captureSeconds = event["captureSeconds"].flatMap(Double.init)
                let text = promptText(value)
                guard text.utf8.count <= 65_536 else { fail("This dictation exceeds the preview's size limit."); return }
                finish()
                if text.isEmpty { failed?("No speech recognized. Check the microphone and language.") }
                else { completed?(text) }
            } else { fail("Unexpected recognition event. Dictation cancelled.") }
        }
    }

    private func update(_ state: State) { self.state = state; changed?(state) }
    private func fail(_ message: String) { finish(); failed?(message) }

    private func finish() {
        timeout?.cancel()
        timeout = nil
        let child = process
        process = nil
        input = nil
        update(.idle)
        if let child, child.isRunning {
            child.terminate()
            Task {
                try? await Task.sleep(for: .seconds(2))
                if child.isRunning { _ = kill(child.processIdentifier, SIGKILL) }
            }
        }
    }

    func cancel() { guard process != nil else { return }; finish() }
}
