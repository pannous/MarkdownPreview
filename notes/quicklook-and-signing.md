# Tricky parts

## Rendering architecture
- Quick Look's data-based HTML previews run with JavaScript disabled, so rendering happens in Swift land:
  `MarkdownRenderer` evaluates marked + highlight.js inside a `JSContext` and returns finished HTML.
  The app and the extension call the same framework; the app just shows the HTML in a `WKWebView`.
- Live reload replaces `#content.innerHTML` via `evaluateJavaScript` instead of reloading the page, which keeps the scroll position.
- Local images are inlined as `data:` URIs by the renderer (hook `resolveImage` injected into JS), so neither
  `loadHTMLString` file-access rules nor the extension sandbox block them. Remote `http(s)` images are left as-is
  (load in the app; Quick Look may block them).
- CSS order matters: `style.css` must come after the highlight.js themes, otherwise `.hljs { padding: 1em }` doubles the code block padding.

## Signing
- `CODE_SIGN_STYLE: Manual` + `CODE_SIGN_IDENTITY: Apple Development` fails with "requires a development team"
  unless `DEVELOPMENT_TEAM` is set. Team ID is the certificate's OU:
  `security find-certificate -c "Apple Development" -p | openssl x509 -noout -subject` → `OU=T7AR9Y9X4N`.
- No provisioning profile is needed: the only entitlements are sandbox ones.

## Quick Look extension
- App extensions must be sandboxed (`com.apple.security.app-sandbox`). Reading sibling image files needs
  `com.apple.security.temporary-exception.files.absolute-path.read-only = ["/"]` (fine outside the App Store).
- Info.plist: `NSExtensionPointIdentifier = com.apple.quicklook.preview`, `QLIsDataBasedPreview = true`,
  `QLSupportedContentTypes = [net.daringfireball.markdown]` (what Spotlight reports for `.md`: `mdls -name kMDItemContentType`).
- The extension links the framework from the host app: `LD_RUNPATH_SEARCH_PATHS` includes `@executable_path/../../../../Frameworks`.
- Registration after install: `lsregister -f -R -trusted`, `pluginkit -a <appex>`, `pluginkit -e use -i <id>`, `qlmanage -r`, `qlmanage -r cache`.
  Check with `pluginkit -m -v | grep -i markdown` (leading `+` = enabled).

## Testing gotchas
- `qlmanage -p -o dir file.md` crashes inside ExtensionFoundation (nil dictionary key) for app-extension previews; use plain `qlmanage -p`.
- Capturing the qlmanage window while it is behind other windows gives a blank white page (even for Apple's HTML preview).
  Bring it frontmost first (`System Events … set frontmost`), then `screencapture -l <windowid>`.
- In zsh `log` is a builtin; use `/usr/bin/log show …`.
- The swiftly toolchain (Swift 6.0.3) can't import CoreGraphics from the macOS 27 SDK; compile probes with `xcrun swiftc`.
- System Events `key code` did not scroll the web view; `cliclick c:x,y kp:page-down` does.
- Documents open as tabs when the system "prefer tabs" setting is on; `open -a` deduplication comes from `NSDocumentController` behind `DocumentGroup`.
