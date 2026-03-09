#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${1:-$ROOT/docs/refactor-audit/data}"

mkdir -p "$OUT_DIR"
cd "$ROOT"

# State management patterns
rg -n --glob '*.swift' -e '@StateObject' -e '@ObservedObject' -e '@EnvironmentObject' -e '@State\b' -e '@Binding' -e '@Published' -e '@AppStorage' -e 'ObservableObject' LockedIn > "$OUT_DIR/pattern_state_locations.txt"
rg -o --glob '*.swift' '@StateObject|@ObservedObject|@EnvironmentObject|@State\b|@Binding|@Published|@AppStorage|ObservableObject' LockedIn | awk -F: '{print $NF}' | sort | uniq -c | sort -nr > "$OUT_DIR/pattern_state_counts.txt"
rg -n --glob '*.swift' '@EnvironmentObject' LockedIn | awk -F: '{print $1}' | sort | uniq -c | sort -nr > "$OUT_DIR/pattern_environmentobject_by_file.txt"

# Concurrency / main actor patterns
rg -n --glob '*.swift' -e '@MainActor' -e '\basync\b' -e '\bawait\b' -e '\bTask\s*\{' -e 'Task\.detached' -e 'DispatchQueue\.main' -e 'MainActor\.run' LockedIn > "$OUT_DIR/pattern_concurrency_locations.txt"
rg -o --glob '*.swift' '@MainActor|\basync\b|\bawait\b|\bTask\s*\{|Task\.detached|DispatchQueue\.main|MainActor\.run' LockedIn | awk -F: '{print $NF}' | sort | uniq -c | sort -nr > "$OUT_DIR/pattern_concurrency_counts.txt"

# Navigation patterns
rg -n --glob '*.swift' -e 'NavigationStack' -e 'navigationDestination' -e 'sheet\(' -e 'fullScreenCover' -e 'alert\(' -e 'confirmationDialog' -e 'popover\(' -e 'NavigationLink' -e 'TabView' -e 'toolbar' -e 'dismiss\(' -e '@Environment\(\.dismiss\)' LockedIn > "$OUT_DIR/pattern_navigation_locations.txt"
rg -o --glob '*.swift' 'NavigationStack|navigationDestination|sheet\(|fullScreenCover|alert\(|confirmationDialog|popover\(|NavigationLink|TabView|toolbar|dismiss\(|@Environment\(\.dismiss\)' LockedIn | awk -F: '{print $NF}' | sort | uniq -c | sort -nr > "$OUT_DIR/pattern_navigation_counts.txt"

# Persistence/storage patterns
rg -n --glob '*.swift' -e 'UserDefaults' -e '@AppStorage' -e 'FileManager' -e 'JSONEncoder' -e 'JSONDecoder' -e 'Data\(contentsOf:' -e 'data\.write\(' -e 'EventKit' -e 'EKEventStore' -e 'Keychain' -e 'CoreData' -e 'NSPersistentContainer' LockedIn > "$OUT_DIR/pattern_persistence_locations.txt"
rg -o --glob '*.swift' 'UserDefaults|@AppStorage|FileManager|JSONEncoder|JSONDecoder|Data\(contentsOf:|data\.write\(|EventKit|EKEventStore|Keychain|CoreData|NSPersistentContainer' LockedIn | awk -F: '{print $NF}' | sort | uniq -c | sort -nr > "$OUT_DIR/pattern_persistence_counts.txt"

# Repetition signals (UI style drift proxies)
rg -n --glob '*.swift' 'Color\(hex:' LockedIn > "$OUT_DIR/pattern_color_hex_locations.txt"
rg -n --glob '*.swift' 'onAppear|onChange\(|onReceive\(' LockedIn > "$OUT_DIR/pattern_lifecycle_locations.txt"

# Logging/debug output patterns
rg -n --glob '*.swift' -e 'print\(' -e 'TODO|FIXME|HACK|XXX' -e '#warning' LockedIn > "$OUT_DIR/pattern_logging_debug_locations.txt"

echo "collect_patterns.sh complete -> $OUT_DIR"
