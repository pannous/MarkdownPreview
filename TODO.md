DONE: Add a collapsible table of contents that navigates to folded headings and updates on live reload.
DONE: Correct the new Contents positioning probe to use WebKit's actual viewport width, including scrollbar clearance.
DONE: Collapse Contents on Escape and move it to the right edge beneath Edit.
TODO: Update the existing Contents positioning assertion from top 12/right 112 to top 52/right 12 after permission to modify that test.
TODO: ~/.swiftly swift 6.0.3 is first in PATH and cannot import Foundation with the macOS 27 SDK; upgrade swiftly's toolchain (or use xcrun swift).
- uniscript probe fails: sample.md now starts with a <:uniscript version=…> block opener line, so '<p>α β γ: this file' is no longer emitted (uncommitted change)
