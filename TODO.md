DONE: Add a collapsible table of contents that navigates to folded headings and updates on live reload.
DONE: Correct the new Contents positioning probe to use WebKit's actual viewport width, including scrollbar clearance.
DONE: Collapse Contents on Escape and move it to the right edge beneath Edit.
TODO: Update the existing Contents positioning assertion from top 12/right 112 to top 52/right 12 after permission to modify that test.
TODO: ~/.swiftly swift 6.0.3 is first in PATH and cannot import Foundation with the macOS 27 SDK; upgrade swiftly's toolchain (or use xcrun swift).
- DONE uniscript probe fails: sample.md now starts with a <:uniscript version=…> block opener line, so '<p>α β γ: this file' is no longer emitted (uncommitted change)
- sample probes '→ αβγδ' and '→ αθοσ ηΩλ' fail since uniscript 822678c keeps spaces next to a word inside a block (now 'α β γ δ'); the expected strings need updating (user's tests, not changed)
- sample probe '<span class="uniscript-warning" title="red does not apply to 𓀀">𓀀</span>' fails since the uniscript libraries keep an unsupported color as color meta ('red on 𓀀 kept as color meta'); expected string needs updating (user's test, not changed)
- Quick Look font attachments (cid:) only verifiable with UI=1: qlmanage -o crashes
- hieroglyph groups render small (NewGardinerOmni scales a quadrat into one em); maybe size-adjust on the Sequence Hieroglyphs face
- TAG suffix effects (<:red A>) need Uniscript Sans to draw the base letter; not in the sequence fonts because a Latin range would restyle all text
- UserFontSchemeHandler logs every served font (trace while the app's font loading is unconfirmed); drop the success NSLog once confirmed
