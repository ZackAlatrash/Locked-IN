#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${1:-$ROOT/docs/refactor-audit/data}"

mkdir -p "$OUT_DIR"
cd "$ROOT"

PBX="LockedIn.xcodeproj/project.pbxproj"

xcodebuild -project LockedIn.xcodeproj -list > "$OUT_DIR/project_target_inventory.txt" 2>&1 || true

# Files referenced in pbx with explicit LockedIn/ paths that are missing on disk
awk '/path = LockedIn\// {
  line=$0;
  sub(/^.*path = /, "", line);
  sub(/;.*/, "", line);
  gsub(/\"/, "", line);
  print line;
}' "$PBX" | sort -u > "$OUT_DIR/pbx_lockedin_paths.txt"

: > "$OUT_DIR/pbx_missing_lockedin_paths.txt"
while IFS= read -r path; do
  [[ -e "$path" ]] || echo "$path" >> "$OUT_DIR/pbx_missing_lockedin_paths.txt"
done < "$OUT_DIR/pbx_lockedin_paths.txt"

# Full pbx swift path references (raw) for manual interpretation
awk '/path = .*\.swift;/ {
  line=$0;
  sub(/^.*path = /, "", line);
  sub(/;.*/, "", line);
  gsub(/\"/, "", line);
  print line;
}' "$PBX" | sort -u > "$OUT_DIR/pbx_swift_path_references_raw.txt"

# On-disk swift files not represented with explicit LockedIn/ path in pbx (heuristic)
awk '/path = LockedIn\/.*\.swift;/ {
  line=$0;
  sub(/^.*path = /, "", line);
  sub(/;.*/, "", line);
  gsub(/\"/, "", line);
  print line;
}' "$PBX" | sort -u > "$OUT_DIR/pbx_swift_paths_prefixed.txt"

rg --files -g '*.swift' LockedIn | sort -u > "$OUT_DIR/fs_swift_paths.txt"

comm -23 "$OUT_DIR/fs_swift_paths.txt" "$OUT_DIR/pbx_swift_paths_prefixed.txt" > "$OUT_DIR/fs_swift_not_in_prefixed_pbx_heuristic.txt" || true
comm -13 "$OUT_DIR/fs_swift_paths.txt" "$OUT_DIR/pbx_swift_paths_prefixed.txt" > "$OUT_DIR/prefixed_pbx_swift_missing_on_disk.txt" || true

# Simulation files included in Sources build phase
rg -n 'Simulation\.swift in Sources' "$PBX" > "$OUT_DIR/pbx_simulation_in_sources.txt" || true

# Project target declarations
rg -n 'PBXNativeTarget|name = |productType =|Tests|test' "$PBX" > "$OUT_DIR/pbx_target_and_test_signals.txt" || true

echo "collect_project_integrity.sh complete -> $OUT_DIR"
