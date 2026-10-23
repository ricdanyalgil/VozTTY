import AppKit
import AVFoundation
import Speech

@MainActor
func emit(_ type: String, _ key: String? = nil, _ value: String? = nil) {
    var event = ["type": type]
    if let key, let value { event[key] = value }
    guard let data = try? JSONSerialization.data(withJSONObject: event), var line = String(data: data, encoding: .utf8) else { return }
    line += "\n"
    FileHandle.standardOutput.write(Data(line.utf8))
}

enum VoiceError: LocalizedError {
    case message(String)
    var errorDescription: String? { switch self { case .message(let text): return text } }
}

@MainActor
final class VoiceEngine: NSObject, AVAudioRecorderDelegate {
    var recorder: AVAudioRecorder?
    var directory: URL?
    var module: SpeechTranscriber?
    var analyzer: SpeechAnalyzer?
    var inputURL: URL?
    var operation: Task<Void, Never>?
    var stopping = false

    func prepare(language: String, inputFile: String?) async {
        do {
            guard #available(macOS 26, *) else { throw VoiceError.message("Voz requer macOS 26 ou superior.") }
            guard SpeechTranscriber.isAvailable else { throw VoiceError.message("O reconhecimento local não está disponível neste Mac.") }
            guard let locale = await SpeechTranscriber.supportedLocale(equivalentTo: Locale(identifier: language)) else {
                throw VoiceError.message("Este idioma não é suportado pelo reconhecimento local deste Mac.")
            }
            let transcriber = SpeechTranscriber(locale: locale, preset: .transcription)
            module = transcriber
            if let download = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
                try await download.downloadAndInstall()
            }
            try Task.checkCancellation()
            if let inputFile {
                inputURL = URL(fileURLWithPath: inputFile)
                emit("ready")
                return
            }
            guard await AVCaptureDevice.requestAccess(for: .audio) else {
                throw VoiceError.message("Autorize o microfone para o VS Code ou Voz Engine em Definições do Sistema → Privacidade e Segurança → Microfone.")
            }
            try Task.checkCancellation()
            guard let format = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber]) else {
                throw VoiceError.message("Não foi possível preparar o formato de áudio.")
            }
            // shortcut: file-backed capture shows text after Stop; use streaming input when live preview is required.
            let folder = FileManager.default.temporaryDirectory.appendingPathComponent("voz-vscode-\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: false, attributes: [.posixPermissions: 0o700])
            directory = folder
            let capture = try AVAudioRecorder(url: folder.appendingPathComponent("audio.caf"), settings: format.settings)
            capture.delegate = self
            guard capture.record() else { throw VoiceError.message("Não foi possível iniciar o microfone.") }
            recorder = capture
            inputURL = capture.url
            emit("ready")
        } catch {
            fail(error.localizedDescription)
        }
    }

    func stop() {
        guard !stopping, let inputURL else { return }
        stopping = true
        recorder?.stop()
        recorder = nil
        operation = Task {
            do { try await transcribe(inputURL) }
            catch { fail(error.localizedDescription) }
        }
    }

    func transcribe(_ url: URL) async throws {
        guard let module else { throw VoiceError.message("O reconhecimento não foi preparado.") }
        let analysis = SpeechAnalyzer(modules: [module])
        analyzer = analysis
        let output = Task { () throws -> String in
            var text = ""
            for try await result in module.results {
                text += String(result.text.characters)
            }
            return text
        }
        do {
            let file = try AVAudioFile(forReading: url)
            _ = try await analysis.analyzeSequence(from: file)
            try await analysis.finalizeAndFinishThroughEndOfInput()
            let text = try await output.value
            try Task.checkCancellation()
            try cleanup()
            emit("final", "text", text)
            exit(0)
        } catch {
            await analysis.cancelAndFinishNow()
            output.cancel()
            throw error
        }
    }

    func cleanup() throws {
        recorder?.stop()
        recorder = nil
        if let directory { try FileManager.default.removeItem(at: directory) }
        directory = nil
    }

    func fail(_ message: String) {
        var description = message
        do { try cleanup() }
        catch { description += " Não foi possível apagar o áudio temporário." }
        emit("error", "message", description)
        exit(1)
    }

    func cancel() {
        operation?.cancel()
        do { try cleanup() }
        catch { emit("error", "message", "Não foi possível apagar o áudio temporário.") }
        exit(0)
    }

    nonisolated func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        let description = error?.localizedDescription ?? "A gravação do microfone falhou."
        Task { @MainActor in fail(description) }
    }

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag { Task { @MainActor in fail("A gravação foi interrompida. Verifique o microfone e tente novamente.") } }
    }
}

@main
struct Main {
    @MainActor static func main() {
        // Broken pipes mean the VS Code session has ended; do not crash before cleanup.
        signal(SIGPIPE, SIG_IGN)
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        let args = Array(CommandLine.arguments.dropFirst())
        var language = "pt-BR"
        var inputFile: String?
        var index = 0
        while index < args.count {
            guard index + 1 < args.count else { emit("error", "message", "Argumentos inválidos."); exit(2) }
            switch args[index] {
            case "--language": language = args[index + 1]
            case "--file": inputFile = args[index + 1]
            default: emit("error", "message", "Argumento desconhecido."); exit(2)
            }
            index += 2
        }
        guard ["pt-BR", "pt-PT", "en-US"].contains(language) else { emit("error", "message", "Idioma inválido."); exit(2) }
        let engine = VoiceEngine()
        engine.operation = Task { await engine.prepare(language: language, inputFile: inputFile) }
        DispatchQueue.global().async {
            while let line = readLine() {
                if line == "stop" { Task { @MainActor in engine.stop() } }
                else if line == "cancel" { Task { @MainActor in engine.cancel() }; return }
                else { Task { @MainActor in engine.fail("Comando de captura inválido.") }; return }
            }
            Task { @MainActor in engine.cancel() }
        }
        // Dispatch sources allow a graceful cleanup when the extension host exits.
        signal(SIGTERM, SIG_IGN)
        signal(SIGINT, SIG_IGN)
        let term = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        let interrupt = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        term.setEventHandler { engine.cancel() }
        interrupt.setEventHandler { engine.cancel() }
        term.resume()
        interrupt.resume()
        withExtendedLifetime((engine, term, interrupt)) { app.run() }
    }
}
