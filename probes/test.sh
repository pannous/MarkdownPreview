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

html="$(./render_cli "$SAMPLE")"
for fragment in '<table>' '<th align="center">Tables</th>' 'class="hljs-keyword"' 'type="checkbox"' 'src="data:image/png;base64,' '<h2 id="table">' 'href="https://example.com"'; do
  check "renderer emits $fragment" grep -qF "$fragment" <<<"$html"
done
check "user-installed fonts named for rare glyphs" grep -qF -- '--fallback-fonts: "Oracular", "開元小篆"' <(./render_cli "$PROBES/fonts/rare_glyphs.md")
check "no fallback fonts when system fonts suffice" bash -c "! grep -q '<style>:root' <<<\"\$0\"" "$html"
loads_no_remote_assets() { ! grep -qE '<(script|link)[^>]+(src|href)="http' <<<"$html"; }
check "renderer loads no remote scripts/styles" loads_no_remote_assets

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
osascript -e 'tell application "MarkdownPreview" to activate' >/dev/null; sleep 1
check "app window captured" capture_window MarkdownPreview app_window.png

echo "$failures failure(s)"
exit "$failures"
