# Uniscript in MarkdownPreview

- Swift package in ~/dev/uniscript (port of the Rust crate, shared data/entities.idx), tests ported.
- Renderer: Uniscript SwiftPM dependency, `convertUniscript` bridge, marked inline extension, only for files starting with `<:`.
- Unknown entities stay visible, marked with the error as tooltip; code spans/blocks untouched.
- Probes: probes/uniscript/{sample,plain}.md, checks in probes/test.sh, app + Quick Look screenshots taken in the background.
- Preserve the user's uncommitted probes/app_window.png.
