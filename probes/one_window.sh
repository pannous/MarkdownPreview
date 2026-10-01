#!/bin/bash
# One window: files opened one after the other, also while the app is in the background (open -g), become tabs of the
# running instance's window instead of windows of their own. Usage: probes/one_window.sh
set -uo pipefail
PROBES="$(cd "$(dirname "$0")" && pwd)"

visible_windows() {  # on-screen document windows of MarkdownPreview (a tab group shows only its selected tab)
  python3 -c '
import Quartz
windows = Quartz.CGWindowListCopyWindowInfo(Quartz.kCGWindowListOptionOnScreenOnly, Quartz.kCGNullWindowID)
print(sum(1 for w in windows if w.get("kCGWindowOwnerName") == "MarkdownPreview" and w.get("kCGWindowLayer") == 0 and str(w.get("kCGWindowName", "")).endswith(".md")))'
}
open -g -a "$HOME/Applications/MarkdownPreview.app" "$PROBES/sample.md"; sleep 3
open -g -a "$HOME/Applications/MarkdownPreview.app" "$PROBES/other.md"; sleep 3
count="$(visible_windows)"
if [ "$count" = 1 ]; then echo "ok   one window, the files are tabs"; else echo "FAIL $count visible windows"; exit 1; fi
