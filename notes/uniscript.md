# Uniscript in the renderer

- Opt-in (user decision): only files whose first two characters are `<:` get converted; all others render as before.
- Where: a marked **inline extension** in `Renderer/Resources/render.js`. Inline extensions run before marked's own
  inline rules, so `\:infinity` is seen before the backslash-escape rule eats the `\`, and `<:alpha>` before it gets
  escaped as text. Code spans and code blocks are never inline-lexed by the extension (code span rule wins at the backtick,
  fenced/indented blocks are block tokens), so code stays literal without any own Markdown parsing.
- Conversion is Swift: `convertUniscript(raw)` injected into the JSContext returns `{text}` or `{error}` from
  `Uniscript.convert` (`{text, warning}` or `{error}`). Errors render as `<span class="uniscript-error" title="…">raw</span>`,
  warnings (no greek form of c, red does not apply to 𓀀, no beside group of a) as `<span class="uniscript-warning">`
  around the converted text of the whole element: a warning carries only the source byte offset of its tag, not the
  output position of the plain character, so the element is the finest unit that can be marked.
- Blocks `<:greek> a b c <:/greek>`: an opener tag converts to "" without error; the extension then consumes through the
  next `<:>`/`<:/…>` (or to the end of the paragraph) and converts it in one go. Markdown inside a block is not parsed
  (spaces there are uniscript operand separators anyway).
- Font fallback now looks at the rendered HTML instead of the Markdown source, so characters produced by uniscript
  (hieroglyphs, TAG controls) also get user-installed fonts named.

## Packaging gotchas
- The package (GitHub `pannous/uniscript`, branch main) bundles `data/entities.idx` (3.4 MB) as a SwiftPM resource.
  Xcode copies `Uniscript_Uniscript.bundle` into the **app's and the appex's** Resources, not into MarkdownRenderer.framework,
  so a probe binary linking the framework crashes with "unable to find bundle named Uniscript_Uniscript" unless the
  bundle sits next to it: `probes/test.sh` symlinks it into probes/.
- `CODE_SIGN_IDENTITY=…` on the xcodebuild command line also reaches the package's resource-bundle target, which has no
  team: "Signing for Uniscript_Uniscript requires a development team". `install.sh` passes `DEVELOPMENT_TEAM` read from project.yml.
- In the uniscript repo `Sources/Uniscript/entities.idx` is a symlink to `data/entities.idx`; SwiftPM resolves it on copy.
- The swiftly toolchain (6.0.3) can't build against the macOS 27 SDK: use `xcrun swift test` there.

- Following `branch: main` is not automatic: Xcode pins the revision in the generated `Package.resolved` **and** in
  `build/SourcePackages/workspace-state.json`; removing only the first (or fetching into the cached clone,
  `-disablePackageRepositoryCache`) still resolved the old commit. `install.sh` removes both before building.

## Screenshots without focus stealing
- `open -g -a MarkdownPreview file.md` + `screencapture -x -o -l <window id>` works while the app stays in the background.
- `qlmanage -p file.md &` + the same capture also worked without bringing qlmanage to the front this time
  (`probes/uniscript/quicklook.png`).
