// Renders a Markdown file to a full HTML page with the built MarkdownRenderer.framework (same code as app + Quick Look).
import Foundation
import MarkdownRenderer
let fileURL = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
print(MarkdownRenderer.shared.renderPage(fileURL: fileURL))
