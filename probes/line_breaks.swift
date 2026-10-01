// Headless check of App/LineBreaks.swift: the Fix button's rewrite that turns every soft newline into a hard break.
// Build: see probes/test.sh
import Foundation

@main
enum LineBreaksProbe {
    static var failures = 0

    static func expect(_ description: String, _ input: String, _ expected: String) {
        let output = LineBreaks.hardened(input)
        print(output == expected ? "ok  " : "FAIL", description)
        if output != expected { failures += 1; print("  got:\n\(output.debugDescription)\n  expected:\n\(expected.debugDescription)") }
    }

    /// The button's action on a real file: rewritten once, a second press leaves it alone.
    static func fixesFile() {
        let fileURL = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("line_breaks.md")
        try! "first line\nsecond line\n".write(to: fileURL, atomically: true, encoding: .utf8)
        defer { try? FileManager.default.removeItem(at: fileURL) }
        LineBreaks.fix(fileURL)
        let fixed = try! String(contentsOf: fileURL, encoding: .utf8)
        print(fixed == "first line  \nsecond line\n" ? "ok  " : "FAIL", "Fix rewrites the file")
        if fixed != "first line  \nsecond line\n" { failures += 1 }
    }

    static func main() {
        expect("consecutive lines get two trailing spaces", "a\nb\nc\n", "a  \nb  \nc\n")
        expect("paragraph ends and blank lines stay untouched", "a\nb\n\nc\n", "a  \nb\n\nc\n")
        expect("existing hard breaks are kept", "a  \nb\\\nc\n", "a  \nb\\\nc\n")
        expect("stray trailing whitespace becomes exactly two spaces", "a \nb\t\nc", "a  \nb  \nc")
        expect("fenced code blocks stay untouched", "a\n```\nx\ny\n```\nb\nc\n", "a\n```\nx\ny\n```\nb  \nc\n")
        expect("tilde fences too", "~~~\nx\ny\n~~~\n", "~~~\nx\ny\n~~~\n")
        expect("already fixed text is unchanged", "a  \nb\n", "a  \nb\n")
        fixesFile()
        print("\(failures) failure(s)")
        exit(Int32(failures))
    }
}
