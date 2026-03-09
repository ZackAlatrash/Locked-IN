#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${1:-$ROOT/docs/refactor-audit/data}"

mkdir -p "$OUT_DIR"
cd "$ROOT"

find . -type f | sort > "$OUT_DIR/all_files.txt"
find LockedIn -type f | sort > "$OUT_DIR/lockedin_files.txt"
find LockedIn -type d | sort > "$OUT_DIR/lockedin_directories.txt"
find LockedIn -maxdepth 8 -type d | sort > "$OUT_DIR/lockedin_tree_maxdepth8.txt"

rg --files -g '*.swift' LockedIn | sort > "$OUT_DIR/swift_files.txt"

{
  echo "GeneratedAtUTC: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "RepoRoot: $ROOT"
  echo "AllFilesCount: $(wc -l < "$OUT_DIR/all_files.txt" | tr -d ' ')"
  echo "LockedInFilesCount: $(wc -l < "$OUT_DIR/lockedin_files.txt" | tr -d ' ')"
  echo "LockedInDirectoriesCount: $(wc -l < "$OUT_DIR/lockedin_directories.txt" | tr -d ' ')"
  echo "SwiftFilesCount: $(wc -l < "$OUT_DIR/swift_files.txt" | tr -d ' ')"
} > "$OUT_DIR/inventory_summary.txt"

awk -F/ 'NF>=2 {print $2}' "$OUT_DIR/swift_files.txt" | sort | uniq -c | sort -nr > "$OUT_DIR/swift_layer_counts.txt"
awk -F/ '$2=="Features" && NF>=3 {print $3}' "$OUT_DIR/swift_files.txt" | sort | uniq -c | sort -nr > "$OUT_DIR/swift_feature_counts.txt"

{
  echo "path,likely_layer,likely_feature"
  while IFS= read -r path; do
    layer=$(echo "$path" | awk -F/ '{print $2}')
    feature=""
    if [[ "$path" == LockedIn/Features/* ]]; then
      feature=$(echo "$path" | awk -F/ '{print $3}')
    elif [[ "$path" == LockedIn/App/* ]]; then
      feature="App"
    elif [[ "$path" == LockedIn/CoreUI/* ]]; then
      feature="CoreUI"
    elif [[ "$path" == LockedIn/Core/* ]]; then
      feature="Core"
    elif [[ "$path" == LockedIn/Application/* ]]; then
      feature="Application"
    elif [[ "$path" == LockedIn/Domain/* ]]; then
      feature="Domain"
    else
      feature="Unknown"
    fi
    echo "$path,$layer,$feature"
  done < "$OUT_DIR/swift_files.txt"
} > "$OUT_DIR/swift_path_index.csv"

echo "collect_inventory.sh complete -> $OUT_DIR"
