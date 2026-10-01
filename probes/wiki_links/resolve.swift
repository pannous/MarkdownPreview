// Headless check of App/WikiLinks.swift: [[page]] links to files that are not next to the document.
// Build: see probes/test.sh
import Foundation

@main
enum WikiLinksProbe {
    static var failures = 0
    static let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("tree")
    static let document = root.appendingPathComponent("index.md")

    static func file(_ path: String) -> URL { root.appendingPathComponent(path) }

    static func expect(_ description: String, _ link: String, _ expected: String?) {
        let found = WikiLinks.resolve(file(link), from: document)?.standardizedFileURL.path
        let ok = found == expected.map { file($0).standardizedFileURL.path }
        print(ok ? "ok  " : "FAIL", description)
        if !ok { failures += 1; print("  got \(found ?? "nil"), expected \(expected ?? "nil")") }
    }

    static func main() {
        for path in ["index.md", "sub/Notes.md", "other_page.md", "deep/guide.md", "elsewhere/guide.md", "a/b/guide.md", "build/hidden.md"] {
            try! FileManager.default.createDirectory(at: file(path).deletingLastPathComponent(), withIntermediateDirectories: true)
            try! "".write(to: file(path), atomically: true, encoding: .utf8)
        }
        defer { try? FileManager.default.removeItem(at: root) }
        expect("a page in a subfolder, any case", "notes.md", "sub/Notes.md")
        expect("space, dash and underscore alike", "other page.md", "other_page.md")
        expect("dir/page only inside a folder ending in dir", "deep/guide.md", "deep/guide.md")
        expect("the shallowest of several matches", "guide.md", "deep/guide.md")
        expect("build output is not searched", "hidden.md", nil)
        expect("a missing page is not found", "test.md", nil)
        let created = try! WikiLinks.create(file("new page.md"))
        let ok = created.lastPathComponent == "new-page.md" && (try? String(contentsOf: created, encoding: .utf8)) == "# new page\n"
        print(ok ? "ok  " : "FAIL", "a missing page is created with its title")
        if !ok { failures += 1 }
        exit(Int32(failures))
    }
}
