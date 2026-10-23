import Foundation

@main
struct Tests {
    @MainActor static func main() async throws {
        precondition(promptText("  Olá!\r\nReveja a API.\t🚀\u{1b}\u{0}  ") == "Olá! Reveja a API. 🚀")
        precondition(promptText("$(teste) `código`") == "$(teste) `código`")
        precondition(!promptText("a\u{8}b\u{9b}c\n").unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }))
        let shell = ShellSession()
        var output = Data()
        shell.output = { output.append($0) }
        try shell.start(executable: "/bin/zsh", arguments: ["-f", "-c", "printf 'READY\\n'; IFS= read -r value; printf 'SUBMITTED:%s\\n' \"$value\""], directory: "/tmp")
        defer { shell.close() }
        for _ in 0..<100 {
            if String(decoding: output, as: UTF8.self).contains("READY") { break }
            try await Task.sleep(for: .milliseconds(30))
        }
        precondition(String(decoding: output, as: UTF8.self).contains("READY"))
        shell.resize(columns: 80, rows: 24)
        shell.write("Texto sem Enter")
        try await Task.sleep(for: .milliseconds(200))
        precondition(!String(decoding: output, as: UTF8.self).contains("SUBMITTED:"))
        shell.write("\n")
        for _ in 0..<100 {
            if String(decoding: output, as: UTF8.self).contains("SUBMITTED:Texto sem Enter") { break }
            try await Task.sleep(for: .milliseconds(30))
        }
        precondition(String(decoding: output, as: UTF8.self).contains("SUBMITTED:Texto sem Enter"))
        print("PASS: native text sanitization, real PTY, resize and no submission without Enter")
    }
}
