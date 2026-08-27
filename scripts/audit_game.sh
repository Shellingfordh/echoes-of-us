#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd "$script_dir/.." && pwd)"
audit_dir="${1:-/tmp/echoes-of-us-completion-audit}"
godot_bin="${GODOT_BIN:-$(command -v godot)}"

mkdir -p "$audit_dir"

cd "$repo_dir"
"$godot_bin" --headless --path game --script res://scripts/tests/completion_audit.gd | tee "$audit_dir/completion-audit.log"
"$godot_bin" --headless --path game --script res://scripts/tests/smoke_test.gd | tee "$audit_dir/smoke-test.log"

if [[ "${ECHOES_SKIP_CAPTURE:-0}" != "1" ]]; then
	"$godot_bin" --path game --script res://scripts/tests/capture_prototype.gd -- "$audit_dir/flow" | tee "$audit_dir/capture.log"
fi

if [[ "${ECHOES_SKIP_CAPTURE:-0}" != "1" ]] && command -v magick >/dev/null 2>&1; then
	magick montage \
		"$audit_dir/flow-prologue.png" \
		"$audit_dir/flow-act1.png" \
		"$audit_dir/flow-act2.png" \
		"$audit_dir/flow-act3-corridor.png" \
		"$audit_dir/flow-act3-warehouse.png" \
		"$audit_dir/flow-act3-rooftop.png" \
		"$audit_dir/flow-act4-move-in.png" \
		"$audit_dir/flow-act4-silence.png" \
		"$audit_dir/flow-act4-stable.png" \
		"$audit_dir/flow-act4-epilogue.png" \
		"$audit_dir/flow-ending.png" \
		-thumbnail 480x270 -tile 3x -geometry +8+8 -background '#17151e' \
		"$audit_dir/contact-sheet.jpg"
fi

git diff --check
echo "[Audit] Complete: $audit_dir"
