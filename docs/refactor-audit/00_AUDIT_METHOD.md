# 00_AUDIT_METHOD

## Purpose and Scope
Pass A is a forensic inventory pass. Objective: document what exists today with evidence, not propose or execute refactors.

Scope included:
- Repository structure and Swift source inventory
- File sizes and complexity proxies
- State/concurrency/navigation/persistence patterns
- Project integrity checks (targets, stale references, simulation-in-sources)
- Dead/unused-code heuristics

Scope excluded:
- Any behavior changes, architecture changes, file moves, or cleanups
- Runtime profiling and AST-level semantic proofs

## Summary
- This audit used reproducible scripts under `tools/refactor-audit/` and stored outputs under `docs/refactor-audit/data/`.
- Manual interpretation was applied only after collecting raw evidence.
- Confidence labels are attached per finding; low-confidence findings are explicitly marked heuristic.

## How the Audit Was Performed
### Automated collection
Scripts created and executed:
1. `tools/refactor-audit/collect_inventory.sh`
- Generates file and folder inventory, Swift file list, layer and feature counts.
2. `tools/refactor-audit/collect_metrics.sh`
- Generates per-file LOC, largest-file lists, threshold buckets, long-function and large-type heuristics.
3. `tools/refactor-audit/collect_patterns.sh`
- Scans for state, concurrency, navigation, persistence, lifecycle, and debug/log patterns.
4. `tools/refactor-audit/collect_project_integrity.sh`
- Captures target/scheme info, stale pbx references, and simulation files in build sources.
5. `tools/refactor-audit/collect_deadcode_signals.sh`
- Produces low-confidence unused/stale candidates and simulation-entrypoint usage checks.

Primary evidence outputs:
- `docs/refactor-audit/data/inventory_summary.txt`
- `docs/refactor-audit/data/metrics_summary.txt`
- `docs/refactor-audit/data/swift_loc_top_60.txt`
- `docs/refactor-audit/data/long_function_heuristics.txt`
- `docs/refactor-audit/data/large_type_heuristics.txt`
- `docs/refactor-audit/data/pattern_*`
- `docs/refactor-audit/data/project_target_inventory.txt`
- `docs/refactor-audit/data/pbx_missing_lockedin_paths.txt`
- `docs/refactor-audit/data/pbx_simulation_in_sources.txt`
- `docs/refactor-audit/data/deadcode_*`

### Manual interpretation
Manual analysis was applied to:
- Severity scoring (Critical/High/Medium/Low)
- Risk type classification (`Code smell`, `Bug risk`, `Architecture risk`, `Production risk`)
- Cross-file drift interpretation where patterns cluster (e.g., duplicated state ownership)

## Heuristics Used
- Large file thresholds: `>150`, `>300`, `>500`, `>1000` LOC
- Long function heuristic: functions `>=60` lines (brace-depth approximation)
- Large type heuristic: class/struct/enum/protocol `>=120` lines (brace-depth approximation)
- Dead-code heuristic: declared type names with single token reference count, preview-only symbol patterns, simulation entrypoint usage scan
- Structural drift heuristics: empty feature subfolders, missing on-disk referenced files, and build-phase inclusion of simulation files

## What Was Measured Automatically vs Inferred Manually
### Measured automatically
- File/folder inventory counts
- LOC totals and top files
- Pattern counts and locations for state/concurrency/navigation/persistence
- Presence/absence signals for test directories and test files
- pbx stale path references and simulation source entries

### Inferred manually
- Architecture drift severity
- Likely responsibility overload in specific files/types
- Likely duplication clusters requiring Pass B semantic tracing

## Limitations
- `xcodebuild -list` output contains simulator/log noise in this environment; target data is still extractable from the same file.
- Dead-code detection is not compiler-grade; findings are confidence-banded and not treated as proof unless corroborated.
- Function/type complexity heuristics are textual and may over/under-estimate in edge cases.
- This pass did not execute runtime flows or UI interaction tests.

## Method Reliability Findings
### Finding 1: Dead-code and complexity metrics are heuristic, not semantic proofs
- Type: Code smell
- Severity: Medium
- Confidence: High confidence
- Evidence:
  - Heuristic scripts: `tools/refactor-audit/collect_metrics.sh`, `tools/refactor-audit/collect_deadcode_signals.sh`.
- Why this is risky now:
  - False positives are possible if interpreted as certainty.
- Pass B follow-up:
  - Re-validate uncertain findings with symbol/index-level tracing.

## What Pass B Must Validate
- True runtime ownership and side effects for navigation + modal coordination.
- Whether suspected duplicated business rules are exact duplicates or intentionally divergent.
- Whether single-reference symbols are truly dead in build/runtime contexts.
- Refactor safety boundaries around god files (`PlanScreen`, `PlanStore`, `CommitmentSystemStore`, `CreateNonNegotiableView`).

## Conclusion
Pass A is evidence-complete for structural and static-pattern diagnostics. Remaining uncertainty is concentrated in semantic equivalence and runtime behavior, which is explicitly deferred to Pass B.
