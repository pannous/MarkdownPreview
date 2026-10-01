DONE: Add a collapsible table of contents that navigates to folded headings and updates on live reload.
DONE: Correct the new Contents positioning probe to use WebKit's actual viewport width, including scrollbar clearance.
DONE: Collapse Contents on Escape and move it to the right edge beneath Edit.
TODO: Update the existing Contents positioning assertion from top 12/right 112 to top 52/right 12 after permission to modify that test.
TODO: ~/.swiftly swift 6.0.3 is first in PATH and cannot import Foundation with the macOS 27 SDK; upgrade swiftly's toolchain (or use xcrun swift).
- DONE uniscript probe fails: sample.md now starts with a <:uniscript version=…> block opener line, so '<p>α β γ: this file' is no longer emitted (uncommitted change)
- sample probes '→ αβγδ' and '→ αθοσ ηΩλ' fail since uniscript 822678c keeps spaces next to a word inside a block (now 'α β γ δ'); the expected strings need updating (user's tests, not changed)
- sample probe '<span class="uniscript-warning" title="red does not apply to 𓀀">𓀀</span>' fails since the uniscript libraries keep an unsupported color as color meta ('red on 𓀀 kept as color meta'); expected string needs updating (user's test, not changed)
- Quick Look font attachments (cid:) only verifiable with UI=1: qlmanage -o crashes
- DONE hieroglyph groups render small (NewGardinerOmni scales a quadrat into one em); maybe size-adjust on the Sequence Hieroglyphs face
- TAG suffix effects (<:red A>) need Uniscript Sans to draw the base letter; not in the sequence fonts because a Latin range would restyle all text
- DONE UserFontSchemeHandler logs every served font (trace while the app's font loading is unconfirmed); drop the success NSLog once confirmed
DONE: Fix button (⌘⇧L) that adds two trailing spaces to soft newlines so they render as line breaks.
TODO: probes/test.sh "user-installed fonts named for rare glyphs" fails (pre-existing, seen 2026-10-01 before the Fix button work).
DONE: Composed ideographic description sequences (⿰讠⿱人工) left a wide gap before double spaces and at the end of bold/italic: WebKit measured each ideograph alone as a line-break item; sequences now sit in a word-break: keep-all span.
TODO: probes/test.sh expects '→ 𓀀𓐰𓁐 ⿰犭句</li>', now '→ 𓀀𓐰𓁐 <span class="description-sequence">⿰犭句</span></li>'; update the expected string once permitted (user's test).
TODO: probes/test.sh composes() uses macOS awk, which compares multibyte strings wrongly ('𓀀𓐰𓁐' == '⿰犭句' is true), so "ideographic description composes in WebKit" passes on the hieroglyph line; and sequence_shaping's range width counts characters (3.00 even when composed). Both checks are false positives.
DONE: Startup: restored tabs load lazily (only the selected tab renders and starts a web process); font fallback answers cached on disk.
TODO: Lazy tab loading verified at launch (1 web process, selected tab loads); switching to a not-yet-loaded tab only reasoned (didBecomeKey), not exercised by a probe (needs UI).
DONE: One app instance (second copies hand their files over), every document and .md link opens as a tab; install.sh unregisters the build copy.
TODO: Clicking a [[wiki link]] opens a tab via NSDocumentController (same path as open events, verified); the click itself is not exercised by a probe (needs UI).
DONE: Extended hieroglyphs (Aegyptus private use, <:gardiner A1C>) were 1.6× smaller than standard ones in the app: fallback fonts covering U+13000 now get the same 155% size-adjust.
DONE: Vertical hieroglyph groups (𓀀𓐰𓁐) drawn 130% so stacked signs are not half-size; Egyptian only.
