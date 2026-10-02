- Contents navigation can reuse the folding ancestor walk and reload hook; native `details` preserves its state while only its link list is replaced.
- Offscreen WKWebView layout reserves scrollbar space, so fixed-position assertions should compare against `document.documentElement.clientWidth`.
- Escape dismissal restores focus to the Contents summary only when focus was within the panel; document focus stays unchanged otherwise.
- uniscript: marked inline extensions run before the escape rule, so \: survives; Xcode puts package resource bundles in the app/appex, not the framework linking the package
- Wiki links [[page]] are a marked inline extension; relative hrefs reuse the app's existing .md link opening
- macOS 27: WebKit no longer applies user-installed fonts named in CSS, and CTFontCreateWithName no longer finds them (returns Helvetica); CoreText's fallback still picks them. Fix: @font-face src userfont://<file> served by UserFontSchemeHandler (app) or as cid: attachments (Quick Look)
- Uniscript sequences (hieroglyph groups with U+13430 joiners, ⿰犭句) need one font for the whole sequence; per-character fallback (CoreText and WebKit) splits them, so their fonts go first behind a unicode-range alias
- Probe pitfall: evaluateJavaScript does not await promises; wait for document.fonts.ready with callAsyncJavaScript or the snapshot shows the font swap

- WebKit (page from loadHTMLString with a file: baseURL) drops a click on a file: link whose file does not exist: no
  decidePolicyFor call, no console error. Existing files navigate normally. Fix: a user script posts local link clicks
  to a WKScriptMessageHandler (MarkdownWebView linkScript). Check with `xcrun swift probes/press_link.swift <window> <link>`
  (AXPress, no mouse) and `log show --info --predicate 'subsystem == "com.pannous.MarkdownPreview"'`.
- SteerMouse's Back / Forward arrive in the app; ⌘[ / ⌘] are now tab switching, folding moved to ⌃[ / ⌃].
- uniscript is on in every file now, the `<:` marker/header only hides the header and warns on foreign versions
