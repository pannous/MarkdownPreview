import AppKit

private let hardBreak = "  "
private let codeFences = ["```", "~~~"]

/// Markdown joins consecutive lines into one paragraph unless a line ends with two spaces (or a backslash).
/// `hardened` adds those two spaces to every line followed by another text line, leaving fenced code alone.
enum LineBreaks {
    static func hardened(_ markdown: String) -> String {
        var lines = markdown.components(separatedBy: "\n")
        var insideFence = false
        for index in lines.indices {
            let line = lines[index]
            if isFence(line) { insideFence.toggle(); continue }
            guard !insideFence, index + 1 < lines.count, needsHardBreak(line, before: lines[index + 1]) else { continue }
            lines[index] = trimmingTrailingWhitespace(line) + hardBreak
        }
        return lines.joined(separator: "\n")
    }

    private static func isFence(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return codeFences.contains { trimmed.hasPrefix($0) }
    }

    private static func needsHardBreak(_ line: String, before nextLine: String) -> Bool {
        let isText = { (line: String) in !line.trimmingCharacters(in: .whitespaces).isEmpty }
        guard isText(line), isText(nextLine), !isFence(nextLine) else { return false }
        return !line.hasSuffix(hardBreak) && !line.hasSuffix("\\")
    }

    private static func trimmingTrailingWhitespace(_ line: String) -> String {
        String(line.reversed().drop { $0 == " " || $0 == "\t" }.reversed())
    }
}

extension LineBreaks {
    /// Rewrites the file in place; beeps when it already has hard breaks everywhere or cannot be written.
    static func fix(_ fileURL: URL) {
        guard let markdown = try? String(contentsOf: fileURL, encoding: .utf8) else { return NSSound.beep() }
        let fixed = hardened(markdown)
        guard fixed != markdown, (try? fixed.write(to: fileURL, atomically: true, encoding: .utf8)) != nil else { return NSSound.beep() }
    }
}
