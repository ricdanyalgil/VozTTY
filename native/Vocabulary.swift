import Foundation

struct Vocabulary {
    static var fileURL: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/VozTTY/vocabulary.txt")
    }
    static let starter = """
    # One name per line. Optional alternatives: Preferred name = alternative | another alternative
    # Matches whole words only, ignoring case. Use short, specific phrases.
    Claude
    Claude Code = Cloud Code
    Codex
    OpenAI Codex = OpenI Codex
    Gemini
    VozTTY
    """
    private let replacements: [String: String]
    private let pattern: NSRegularExpression

    static func load() throws -> Vocabulary {
        let url = fileURL
        guard FileManager.default.fileExists(atPath: url.path) else { return try Vocabulary(starter) }
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let data = try handle.read(upToCount: 32_769) ?? Data()
        guard data.count <= 32_768, let text = String(data: data, encoding: .utf8) else {
            throw error("Use UTF-8 text smaller than 32 KB.")
        }
        return try Vocabulary(text)
    }

    static func createFileIfNeeded() throws {
        let url = fileURL
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        if !FileManager.default.fileExists(atPath: url.path) {
            try Data((starter + "\n").utf8).write(to: url, options: .withoutOverwriting)
            try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
        }
    }

    init(_ text: String) throws {
        var entries: [String: String] = [:]
        var count = 0
        for line in text.components(separatedBy: .newlines) {
            let line = line.trimmingCharacters(in: .whitespaces)
            if line.isEmpty || line.hasPrefix("#") { continue }
            let parts = line.components(separatedBy: "=")
            guard parts.count <= 2 else { throw Self.error("Use only one '=' per line.") }
            let name = parts[0].trimmingCharacters(in: .whitespaces)
            let aliases = parts.count == 2 ? parts[1].components(separatedBy: "|") : []
            for raw in [name] + aliases {
                let phrase = raw.trimmingCharacters(in: .whitespaces)
                guard !phrase.isEmpty, phrase.count <= 80,
                      phrase.rangeOfCharacter(from: .controlCharacters) == nil,
                      !phrase.contains("|") else { throw Self.error("Names and alternatives must contain 1–80 characters without control characters.") }
                count += 1
                guard count <= 100 else { throw Self.error("Use at most 100 names and alternatives.") }
                let key = phrase.lowercased()
                if let existing = entries[key], existing != name { throw Self.error("An alternative belongs to more than one name.") }
                entries[key] = name
            }
        }
        replacements = entries
        let words = entries.keys.sorted { $0.count == $1.count ? $0 < $1 : $0.count > $1.count }
            .map(NSRegularExpression.escapedPattern(for:)).joined(separator: "|")
        pattern = try NSRegularExpression(pattern: words.isEmpty ? "(?!)" : "(?<![\\p{L}\\p{M}\\p{N}_])(?:\(words))(?![\\p{L}\\p{M}\\p{N}_])", options: .caseInsensitive)
    }

    func apply(to text: String) -> String {
        let result = NSMutableString(string: text)
        for match in pattern.matches(in: text, range: NSRange(text.startIndex..., in: text)).reversed() {
            let key = (text as NSString).substring(with: match.range).lowercased()
            if let name = replacements[key] { result.replaceCharacters(in: match.range, with: name) }
        }
        return result as String
    }

    private static func error(_ message: String) -> NSError {
        NSError(domain: "VozTTY.Vocabulary", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid vocabulary.txt. \(message)"])
    }
}
