// Headless check of section folding: the ⌘/⌃ [ ] key mapping of App/Folding.swift and App/folding.js running in an
// offscreen WKWebView (no window). Build: see probes/test.sh
import AppKit
import WebKit

private let page = """
<html><head></head><body><article id="content">
<h1 id="a">A</h1><p>a text</p>
<h2 id="a1">A1</h2><p>a1 text</p>
<h3 id="a1x">A1x</h3><p>a1x text</p>
<h2 id="a2">A2</h2><p>a2 text</p>
<h2 id="empty">Empty</h2>
<h1 id="b">B</h1><p>b text</p>
</article></body></html>
"""
private let visibleParagraphs = "[...document.querySelectorAll('p')].filter(p => p.offsetParent).map(p => p.textContent.split(' ')[0]).join(',')"

@main
enum FoldingProbe {
    static var failures = 0

    static func expect(_ description: String, _ condition: Bool) {
        print(condition ? "ok  " : "FAIL", description)
        if !condition { failures += 1 }
    }

    static func key(_ characters: String, _ modifiers: NSEvent.ModifierFlags) -> NSEvent {
        NSEvent.keyEvent(with: .keyDown, location: .zero, modifierFlags: modifiers, timestamp: 0, windowNumber: 0, context: nil,
                         characters: characters, charactersIgnoringModifiers: characters, isARepeat: false, keyCode: 0)!
    }

    @MainActor static func evaluate(_ webView: WKWebView, _ script: String) async -> String {
        (try? await webView.evaluateJavaScript(script)).map { "\($0)" } ?? "<error>"
    }

    @MainActor static func main() async {
        let cases: [(String, NSEvent.ModifierFlags, Folding.Action?)] = [
            ("[", .command, .collapse), ("[", .control, .collapse), ("{", [.command, .shift], .collapse),
            ("]", .command, .expand), ("]", .control, .expand), ("}", [.control, .shift], .expand),
            ("[", [], nil), ("[", [.command, .option], nil), ("]", [.command, .control], nil), ("e", .command, nil),
        ]
        for (characters, modifiers, expected) in cases {
            expect("\(modifiers.rawValue) '\(characters)' → \(expected.map { "\($0)" } ?? "ignored")", Folding.action(for: key(characters, modifiers)) == expected)
        }

        let script = try! String(contentsOf: URL(fileURLWithPath: #filePath).deletingLastPathComponent().appendingPathComponent("../App/folding.js"), encoding: .utf8)
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.addUserScript(WKUserScript(source: script, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 800, height: 600), configuration: configuration)
        webView.loadHTMLString(page, baseURL: nil)
        while await evaluate(webView, "typeof foldDeepest") != "function" { try? await Task.sleep(for: .milliseconds(50)) }

        func step(_ description: String, _ call: String, _ expected: String) async {
            let visible = await evaluate(webView, "\(call); \(visibleParagraphs)")
            expect("\(description) → \(expected) (got \(visible))", visible == expected)
        }
        await step("nothing folded", "0", "a,a1,a1x,a2,b")
        expect("heading without content is not foldable", await evaluate(webView, "document.getElementById('empty').className") == "")
        await step("collapse deepest level (h3)", Folding.Action.collapse.rawValue, "a,a1,a2,b")
        await step("collapse next level (h2)", Folding.Action.collapse.rawValue, "a,b")
        await step("collapse top level (h1)", Folding.Action.collapse.rawValue, "")
        await step("collapse with everything folded is a no-op", Folding.Action.collapse.rawValue, "")
        await step("expand shallowest level (h1)", Folding.Action.expand.rawValue, "a,b")
        await step("expand next level (h2)", Folding.Action.expand.rawValue, "a,a1,a2,b")
        await step("click on A1 heading collapses it again", "document.getElementById('a1').click()", "a,a2,b")
        await step("folds survive a content swap (live reload)",
                   "document.getElementById('content').innerHTML = document.getElementById('content').innerHTML; refreshFolds()", "a,a2,b")
        await step("expand h2 then h3", "\(Folding.Action.expand.rawValue); \(Folding.Action.expand.rawValue)", "a,a1,a1x,a2,b")

        print("\(failures) failure(s)")
        exit(Int32(failures))
    }
}
