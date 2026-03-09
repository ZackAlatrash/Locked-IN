#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${1:-$ROOT/docs/refactor-audit/data}"

mkdir -p "$OUT_DIR"
cd "$ROOT"

SWIFT_LIST="$OUT_DIR/swift_files.txt"
if [[ ! -f "$SWIFT_LIST" ]]; then
  rg --files -g '*.swift' LockedIn | sort > "$SWIFT_LIST"
fi

: > "$OUT_DIR/swift_loc_by_file.txt"
while IFS= read -r f; do
  [[ -f "$f" ]] || continue
  lines=$(wc -l < "$f" | tr -d ' ')
  printf "%6d %s\n" "$lines" "$f" >> "$OUT_DIR/swift_loc_by_file.txt"
done < "$SWIFT_LIST"

sort -nr "$OUT_DIR/swift_loc_by_file.txt" > "$OUT_DIR/swift_loc_by_file_sorted.txt"
head -n 60 "$OUT_DIR/swift_loc_by_file_sorted.txt" > "$OUT_DIR/swift_loc_top_60.txt"

awk '$1 > 150 {print}' "$OUT_DIR/swift_loc_by_file_sorted.txt" > "$OUT_DIR/swift_loc_over_150.txt"
awk '$1 > 300 {print}' "$OUT_DIR/swift_loc_by_file_sorted.txt" > "$OUT_DIR/swift_loc_over_300.txt"
awk '$1 > 500 {print}' "$OUT_DIR/swift_loc_by_file_sorted.txt" > "$OUT_DIR/swift_loc_over_500.txt"
awk '$1 > 1000 {print}' "$OUT_DIR/swift_loc_by_file_sorted.txt" > "$OUT_DIR/swift_loc_over_1000.txt"

TOTAL_LOC=$(awk '{sum += $1} END {print sum+0}' "$OUT_DIR/swift_loc_by_file.txt")
TOTAL_SWIFT=$(wc -l < "$SWIFT_LIST" | tr -d ' ')

{
  echo "GeneratedAtUTC: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "SwiftFilesCount: $TOTAL_SWIFT"
  echo "TotalSwiftLOC: $TOTAL_LOC"
  echo "FilesOver150LOC: $(wc -l < "$OUT_DIR/swift_loc_over_150.txt" | tr -d ' ')"
  echo "FilesOver300LOC: $(wc -l < "$OUT_DIR/swift_loc_over_300.txt" | tr -d ' ')"
  echo "FilesOver500LOC: $(wc -l < "$OUT_DIR/swift_loc_over_500.txt" | tr -d ' ')"
  echo "FilesOver1000LOC: $(wc -l < "$OUT_DIR/swift_loc_over_1000.txt" | tr -d ' ')"
} > "$OUT_DIR/metrics_summary.txt"

perl -e '
use strict; use warnings;
my @files = `cat "$ARGV[0]"`; chomp @files;
my @rows;
for my $f (@files) {
  open my $fh, "<", $f or next;
  my @lines = <$fh>; close $fh;
  my $in = 0; my $depth = 0; my $start = 0; my $sig = "";
  for (my $i=0; $i<@lines; $i++) {
    my $line = $lines[$i];
    if (!$in) {
      if ($line =~ /\bfunc\s+([A-Za-z0-9_]+)/ && $line =~ /\{/) {
        $in = 1; $start = $i+1; ($sig = $line) =~ s/\s+$//;
        my $o = () = $line =~ /\{/g; my $c = () = $line =~ /\}/g; $depth = $o - $c;
        if ($depth <= 0) { my $len = ($i+1)-$start+1; push @rows, [$len,$f,$start,$sig] if $len >= 60; $in = 0; }
      }
    } else {
      my $o = () = $line =~ /\{/g; my $c = () = $line =~ /\}/g; $depth += $o - $c;
      if ($depth <= 0) { my $len = ($i+1)-$start+1; push @rows, [$len,$f,$start,$sig] if $len >= 60; $in = 0; }
    }
  }
}
@rows = sort { $b->[0] <=> $a->[0] } @rows;
for my $r (@rows) { printf "%5d %s:%d %s\n", @$r; }
' "$SWIFT_LIST" > "$OUT_DIR/long_function_heuristics.txt"

perl -e '
use strict; use warnings;
my @files = `cat "$ARGV[0]"`; chomp @files;
my @rows;
for my $f (@files) {
  open my $fh, "<", $f or next;
  my @lines = <$fh>; close $fh;
  my $in = 0; my $depth = 0; my $start = 0; my $sig = "";
  for (my $i=0; $i<@lines; $i++) {
    my $line = $lines[$i];
    if (!$in) {
      if ($line =~ /\b(class|struct|enum|actor|protocol)\s+[A-Za-z0-9_]+/ && $line =~ /\{/) {
        $in = 1; $start = $i+1; ($sig = $line) =~ s/\s+$//;
        my $o = () = $line =~ /\{/g; my $c = () = $line =~ /\}/g; $depth = $o - $c;
        if ($depth <= 0) { my $len = ($i+1)-$start+1; push @rows, [$len,$f,$start,$sig] if $len >= 120; $in = 0; }
      }
    } else {
      my $o = () = $line =~ /\{/g; my $c = () = $line =~ /\}/g; $depth += $o - $c;
      if ($depth <= 0) { my $len = ($i+1)-$start+1; push @rows, [$len,$f,$start,$sig] if $len >= 120; $in = 0; }
    }
  }
}
@rows = sort { $b->[0] <=> $a->[0] } @rows;
for my $r (@rows) { printf "%5d %s:%d %s\n", @$r; }
' "$SWIFT_LIST" > "$OUT_DIR/large_type_heuristics.txt"

: > "$OUT_DIR/declaration_density_proxy.txt"
while IFS= read -r f; do
  [[ -f "$f" ]] || continue
  count=$(rg -c '^[[:space:]]*(func|var |let |@Published|@State|@AppStorage)' "$f" || true)
  printf "%6d %s\n" "$count" "$f" >> "$OUT_DIR/declaration_density_proxy.txt"
done < "$SWIFT_LIST"
sort -nr "$OUT_DIR/declaration_density_proxy.txt" > "$OUT_DIR/declaration_density_proxy_sorted.txt"

echo "collect_metrics.sh complete -> $OUT_DIR"
