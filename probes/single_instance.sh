#!/bin/bash
# One running MarkdownPreview: a forced second copy (open -n, here the build output) hands its file to the running
# instance and exits. Opens a background window (open -g, no focus change). Usage: probes/single_instance.sh
set -uo pipefail
export LC_ALL=C
PROBES="$(cd "$(dirname "$0")" && pwd)"
SECOND_COPY="$PROBES/../build/Build/Products/Release/MarkdownPreview.app"
HANDED_FILE="$PROBES/uniscript/cn.md"

instances() { ps -axo pid,command | grep '[M]arkdownPreview.app/Contents/MacOS/MarkdownPreview$' | awk '{print $1}'; }
osascript -e 'quit app "MarkdownPreview"' >/dev/null 2>&1; sleep 1
open -g -a "/Applications/MarkdownPreview.app" "$PROBES/sample.md"; sleep 3
first="$(instances)"
open -g -n -a "$SECOND_COPY" "$HANDED_FILE"; sleep 4
failures=0
if [ "$(instances)" = "$first" ]; then echo "ok   second copy exited, one instance (pid $first)"; else echo "FAIL instances: $(instances | tr '\n' ' ') (first $first)"; failures=1; fi
if lsof -p "$first" 2>/dev/null | grep -qF "$HANDED_FILE"; then echo "ok   running instance opened the handed file"; else echo "FAIL running instance did not open $HANDED_FILE"; failures=$((failures + 1)); fi
exit "$failures"
