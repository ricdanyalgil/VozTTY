import Foundation

@main
struct VocabularyTests {
    static func main() throws {
        let vocabulary = try Vocabulary("Claude\nClaude Code = Cloud Code\nCodex\nGemini\nBlueAuth = Blue Auth\nC++\nBibs = Bips")
        assert(vocabulary.apply(to: "cloud code, CODEX e gemini. Blue Auth!") == "Claude Code, Codex e Gemini. BlueAuth!")
        assert(vocabulary.apply(to: "cloud storage; Claudeville; my_codex; codex123; ácodex; Bips.") == "cloud storage; Claudeville; my_codex; codex123; ácodex; Bibs.")
        assert(vocabulary.apply(to: "🙂 c++ e claude") == "🙂 C++ e Claude")
        let empty = try Vocabulary("")
        assert(empty.apply(to: "cloud") == "cloud")
        let singlePass = try Vocabulary("One = Two\nThree = One word")
        assert(singlePass.apply(to: "Two word") == "One word")
        for invalid in ["A = ", "A = B = C", "A = same\nB = same", String(repeating: "a", count: 81), "A\tB", (0...100).map { "Name\($0)" }.joined(separator: "\n")] {
            do { _ = try Vocabulary(invalid); fatalError("Invalid vocabulary accepted") } catch { }
        }
        let starter = try String(contentsOfFile: "vocabulary.txt", encoding: .utf8)
        assert(starter.trimmingCharacters(in: .newlines) == Vocabulary.starter)
        print("Vocabulary tests passed")
    }
}
