#!/bin/bash
# Real end-to-end checks against the installed app: renderer output, Quick Look registration + preview, app window.
# Screenshots land in probes/ for visual inspection (quicklook.png, app_window.png). Window checks only run with UI=1.
set -uo pipefail

PROBES="$(cd "$(dirname "$0")" && pwd)"
FRAMEWORKS="$PROBES/../build/Build/Products/Release"
EXTENSION_ID="com.pannous.MarkdownPreview.QuickLook"
SAMPLE="$PROBES/sample.md"
failures=0

check() {  # check <description> <command...>
  local description="$1"; shift
  if "$@" >/dev/null 2>&1; then echo "ok   $description"; else echo "FAIL $description"; failures=$((failures + 1)); fi
}
compile() { xcrun swiftc -O "$PROBES/$1.swift" -o "$PROBES/$1" "${@:2}"; }
capture_window() { screencapture -x -o -l "$("$PROBES/window_id" "$1" | head -1)" "$PROBES/$2"; }

cd "$PROBES"
compile window_id
compile render_cli -F "$FRAMEWORKS" -Xlinker -rpath -Xlinker "$FRAMEWORKS"
# the app and the extension carry the Uniscript index bundle next to them; probe binaries linking the framework find it here
ln -sfn "$FRAMEWORKS/Uniscript_Uniscript.bundle" "$PROBES/Uniscript_Uniscript.bundle"

html="$(./render_cli "$SAMPLE")"
for fragment in '<table>' '<th align="center">Tables</th>' 'class="hljs-keyword"' 'type="checkbox"' 'src="data:image/png;base64,' '<h2 id="table">' 'href="https://example.com"'; do
  check "renderer emits $fragment" grep -qF "$fragment" <<<"$html"
done
check "user-installed fonts named for rare glyphs" grep -qF -- '--fallback-fonts: "Oracular", "開元小篆"' <(./render_cli "$PROBES/fonts/rare_glyphs.md")
check "extended hieroglyph fonts enlarged like the standard ones" grep -qE '@font-face \{ font-family: "Aegyptus"; src: url\("[^"]+"\); size-adjust: 155%; \}' <(./render_cli "$PROBES/uniscript/a1c.md")
check "no fallback fonts when system fonts suffice" bash -c "! grep -q '<style>:root' <<<\"\$0\"" "$html"
loads_no_remote_assets() { ! grep -qE '<(script|link)[^>]+(src|href)="http' <<<"$html"; }
check "renderer loads no remote scripts/styles" loads_no_remote_assets

# font lookups are cached on disk: a cold and a warm render must agree, and the warm one skips CoreText's fallback search
FONT_CACHE="$HOME/Library/Caches/com.pannous.MarkdownPreview/user-fonts.json"
rm -f "$FONT_CACHE"
cold_html="$(./render_cli "$PROBES/fonts/many_characters.md")"
check "font cache written" test -s "$FONT_CACHE"
warm_start=$(perl -MTime::HiRes=time -e 'print time')
warm_html="$(./render_cli "$PROBES/fonts/many_characters.md")"
warm_ms=$(perl -MTime::HiRes=time -e "printf '%d', (time - $warm_start) * 1000")
check "cached render equals uncached render" test "$cold_html" = "$warm_html"
check "cached render of 3000 distinct characters is fast (${warm_ms} ms < 150 ms, uncached ~300 ms)" test "$warm_ms" -lt 150

uniscript_html="$(./render_cli "$PROBES/uniscript/sample.md")"
for fragment in '<p>α β γ: this file' 'Uniscript in 𝔐arkdown</h1>' '→ ∞</li>' '→ 𝔄𝔟𝔠</li>' '→  α β γ δ </li>' '→  αθοσ  ηΩλ</li>' '→ 🔴 🤎</li>' \
  $'→ A\xf3\xa0\x81\xb2\xf3\xa0\x81\x8d</li>' '→ ∀ x ∈ ℝ</li>' '→ 𓀀𓐰𓁐 ⿰犭句</li>' '→ a literal &lt;: marker' '<strong>Bold α</strong>' '<td>ℝ</td>' \
  '<span class="uniscript-error" title="unknown uniscript entity: nosuchthing">&lt;:nosuchthing&gt;</span>' \
  '<span class="uniscript-error" title="unknown uniscript entity: nosuchthing">\:nosuchthing</span>' \
  '<span class="uniscript-warning" title="no greek form of c">c</span>' '<span class="uniscript-warning" title="red on 𓀀 kept as color meta"><span style="color: red">𓀀</span></span>' \
  '<span class="uniscript-warning" title="no beside group of a">ab</span>' \
  '<code>&lt;:alpha&gt; \:infinity</code>' '<code class="hljs language-">&lt;:alpha&gt; \:infinity &lt;:fracture A&gt;' '&lt;:beta&gt; in an indented block'; do
  check "uniscript: renderer emits $fragment" grep -qF "$fragment" <<<"$uniscript_html"
done
check "uniscript in wasp code blocks" grep -qF '<code class="hljs language-wasp">circle := π * r² ' <<<"$uniscript_html"
check "uniscript marks in wasp code blocks" grep -qF '∞ <span class="uniscript-error" title="unknown uniscript entity: nosuchthing">&lt;:nosuchthing&gt;</span> <span class="uniscript-warning" title="no greek form of c">c</span>' <<<"$uniscript_html"
check "uniscript in warp code blocks of any file" grep -qF '<code class="hljs language-warp">α + β' <(./render_cli "$PROBES/uniscript/plain.md")
check "uniscript cn alias by pinyin" grep -qF 'Chinese by pinyin: 口 is 口.' <(./render_cli "$PROBES/uniscript/cn.md")
check "uniscript header hidden" bash -c "! grep -q 'uniscript version' <<<\"\$0\"" "$uniscript_html"
check "higher uniscript versions read without warning" grep -qF '<p>α under a version' <(./render_cli "$PROBES/uniscript/other_version.md")
check "foreign uniscript version warned" grep -qF '<span class="uniscript-warning" title="unsupported uniscript version https://example.com/other">' <(./render_cli "$PROBES/uniscript/foreign_version.md")
check "uniscript on after a foreign header" grep -qF 'α under a version' <(./render_cli "$PROBES/uniscript/foreign_version.md")
check "uniscript meta color as CSS" grep -qF 'Colored hieroglyph: <span style="color: red">𓀀</span>, orange A: <span style="color: #ff8800">A</span>.' <(./render_cli "$PROBES/colors/meta_color.md")
check "uniscript only in files starting with <:" grep -qF 'so &lt;:alpha&gt; and &lt;:fracture A&gt; are shown' <(./render_cli "$PROBES/uniscript/plain.md")

wiki_html="$(./render_cli "$PROBES/wiki_links/links.md")"
for fragment in 'is <a href="docs/uniscript.md">docs/uniscript.md</a>.' '<a href="notes.md">notes</a>' '<a href="other%20page.md">the other page</a>' '<a href="guide.md#setup">guide#setup</a>' '<code>[[docs/uniscript.md]]</code>'; do
  check "wiki links: renderer emits $fragment" grep -qF "$fragment" <<<"$wiki_html"
done

xcrun swiftc -O -parse-as-library "$PROBES/sequence_shaping.swift" -o "$PROBES/sequence_shaping" -F "$FRAMEWORKS" -Xlinker -rpath -Xlinker "$FRAMEWORKS"
./render_cli "$PROBES/uniscript/groups.md" > "$PROBES/uniscript/groups.html"
shaping="$("$PROBES/sequence_shaping" "$PROBES/uniscript/groups.html" "$PROBES/uniscript/groups.png")"
composes() { awk -v text="$1" '$2 == text && $1 < 1.6 { found = 1 } END { exit !found }' <<<"$shaping"; }
check "stacked hieroglyph groups enlarged" grep -qF '<span class="stacked-hieroglyphs">𓀀𓐰𓁐</span>' "$PROBES/uniscript/groups.html"
check "hieroglyphs enlarged" grep -qF 'unicode-range: U+13000-143FF; size-adjust: 155%;' "$PROBES/uniscript/groups.html"
check "hieroglyph group composes in WebKit" composes '𓀀𓐰𓁐'
check "ideographic description composes in WebKit" composes '⿰犭句'
check "brackets keep the text font" grep -qF '16.02 Brackets' <<<"$shaping"
xcrun swiftc -O -parse-as-library "$PROBES/ids_spacing.swift" -o "$PROBES/ids_spacing" -F "$FRAMEWORKS" -Xlinker -rpath -Xlinker "$FRAMEWORKS"
check "description sequences leave no gap (double spaces, bold, inline-block)" "$PROBES/ids_spacing"

xcrun swiftc -parse-as-library "$PROBES/../App/Zoom.swift" "$PROBES/../App/KeyShortcut.swift" "$PROBES/zoom_keys.swift" -o "$PROBES/zoom_keys" 2>/dev/null
check "zoom shortcuts (⌘/⌃ with =/+/-/_/0)" "$PROBES/zoom_keys"
xcrun swiftc -parse-as-library "$PROBES/../App/Folding.swift" "$PROBES/../App/KeyShortcut.swift" "$PROBES/fold_sections.swift" -o "$PROBES/fold_sections" 2>/dev/null
check "section folding (⌘/⌃ [ ], click, survives reload) in an offscreen WKWebView" "$PROBES/fold_sections"

xcrun swiftc -parse-as-library "$PROBES/../App/LineBreaks.swift" "$PROBES/line_breaks.swift" -o "$PROBES/line_breaks" 2>/dev/null
check "Fix button turns newlines into hard line breaks (fences untouched)" "$PROBES/line_breaks"
xcrun swiftc -parse-as-library "$PROBES/../App/WikiLinks.swift" "$PROBES/wiki_links/resolve.swift" -o "$PROBES/wiki_links/resolve" 2>/dev/null
check "wiki links to pages elsewhere in the folder tree, missing ones named for the editor" "$PROBES/wiki_links/resolve"
xcrun swiftc -parse-as-library "$PROBES/../App/TabNavigation.swift" "$PROBES/tab_keys.swift" -o "$PROBES/tab_keys" 2>/dev/null
check "previous / next tab with ⌘← ⌘→ and the mouse's back / forward buttons" "$PROBES/tab_keys"

check "Quick Look extension enabled" bash -c "pluginkit -m -v -i $EXTENSION_ID | grep -q '^+'"
check "Markdown extension listed" bash -c "pluginkit -m -v | grep -qi markdown"

if [ -z "${UI:-}" ]; then  # window checks open windows and steal focus: only with UI=1
  echo "$failures failure(s) (headless)"
  exit "$failures"
fi

qlmanage -p "$SAMPLE" >/dev/null 2>&1 &
sleep 4
osascript -e 'tell application "System Events" to set frontmost of (first process whose name is "qlmanage") to true' >/dev/null
sleep 2
check "qlmanage preview window captured" capture_window qlmanage quicklook.png
check "Quick Look ran our extension" bash -c "/usr/bin/log show --last 15s --predicate 'process == \"MarkdownQuickLook\"' | grep -q MarkdownQuickLook"
pkill -x qlmanage

open -a MarkdownPreview "$SAMPLE"; sleep 3
open -a MarkdownPreview "$SAMPLE"; sleep 2
check "reopening the same file keeps one window" test "$(osascript -e 'tell application "System Events" to count (windows of process "MarkdownPreview" whose name is "sample.md")')" = 1
check "one instance: a second copy hands its file over and exits" "$PROBES/single_instance.sh"
check "one window: files opened in the background become tabs" "$PROBES/one_window.sh"
osascript -e 'tell application "MarkdownPreview" to activate' >/dev/null; sleep 1
check "app window captured" capture_window MarkdownPreview app_window.png

echo "$failures failure(s)"
exit "$failures"
