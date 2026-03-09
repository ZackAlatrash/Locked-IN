#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUT_DIR="${1:-$ROOT/docs/refactor-audit/data}"

mkdir -p "$OUT_DIR"
cd "$ROOT"

# Heuristic: declared types that appear exactly once in token search (likely self-only references)
perl -e '
use strict; use warnings;
my @files = `rg --files -g "*.swift" LockedIn`;
chomp @files;
my %decl;
for my $f (@files){
  open my $fh,"<",$f or next;
  while(my $line = <$fh>){
    if($line =~ /^\s*(?:final\s+)?(?:class|struct|enum|protocol)\s+([A-Za-z_][A-Za-z0-9_]*)\b/){
      $decl{$1} //= $f;
    }
  }
  close $fh;
}
for my $name (sort keys %decl){
  my $count = `rg -o --glob "*.swift" -w "$name" LockedIn | wc -l`;
  $count =~ s/^\s+|\s+$//g;
  if($count eq "1"){
    print "$name\t$decl{$name}\n";
  }
}
' > "$OUT_DIR/deadcode_single_reference_type_candidates.txt"

# Preview-only declarations (usually non-production but useful to track)
rg -n --glob '*.swift' '_Previews' LockedIn > "$OUT_DIR/deadcode_preview_symbols.txt" || true

# Simulation entry points and call sites (no calls usually means stale harness code)
for fn in \
  runRepositorySimulation \
  runNonNegotiableEngineSimulation \
  runCommitmentSystemSimulation \
  runPlanRegulatorSimulation \
  runPlanCompletionReconciliationSimulation \
  runCommitmentPolicyEngineSimulation
  do
    echo "== $fn ==" >> "$OUT_DIR/deadcode_simulation_entrypoints_and_uses.txt"
    rg -n --glob '*.swift' "$fn" LockedIn >> "$OUT_DIR/deadcode_simulation_entrypoints_and_uses.txt" || true
  done

# Single-reference spot-check for known candidates
: > "$OUT_DIR/deadcode_known_candidate_spotcheck.txt"
for sym in CockpitKpiCard CockpitNonNegotiableCard LiquidGlassNavDemosRootView MockPlanCalendarProvider PlaceholderAIService; do
  echo "== $sym ==" >> "$OUT_DIR/deadcode_known_candidate_spotcheck.txt"
  rg -n --glob '*.swift' -w "$sym" LockedIn >> "$OUT_DIR/deadcode_known_candidate_spotcheck.txt" || true
done

echo "collect_deadcode_signals.sh complete -> $OUT_DIR"
