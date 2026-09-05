# ISSUE-002 — Search: maximal match still scans the remaining haystack

State: Investigating
Authorized-Work: Not-Selected
Publication-Target: Not-Selected
External-Reference: Not published.
Contribution-Priority: High
Root-Cause-Confidence: High
Finding-Category: Performance
Created: 2026-09-05
Updated: 2026-09-05
Source: `upstream/main@d32beb4d396e0431f487ccf734a451a145ba7c53`

## Root-Cause

Root-Cause [S]: `Find` under `LeftmostLongest` keeps scanning after finding a match that no pattern can exceed.

## Reach-and-Impact

Reach [S]: `Find` reaches the path directly; `Count` repeatedly invokes it from successive match ends.
Impact [O]: Runtime rose from 126–144 µs at 256 bytes to 8.12–8.81 ms at 2,048 bytes.

## Evidence

- [S] `automaton.go:74-82` — only `LeftmostFirst` returns immediately after a match.
- [S] `automaton.go:321-335` — `Count` invokes `Find` for every non-overlapping match.
- [S] `dfa.go:116-127` — all pattern lengths are already available during compilation.
- [O] `go test -run '^$' -bench '^BenchmarkEvidenceCountLongest$' -benchmem -benchtime=100ms -count=3` → 8× input increased runtime by roughly 60×; Go 1.27.1, linux/amd64, Ryzen 9 5950X.

## Prior-Art

Coverage: local ledger; checked=2026-09-05.
Gaps: Upstream issues, pull requests, discussions, and releases remain unchecked.

Contribution fit: Undecided — measurement and prior-art research remain required.

## Proposed-Change

Store the maximum compiled pattern length and return once `Find` has a match of that length.

## Scope-and-Constraints

- Preserve: Leftmost ordering, equal-length tie behavior, offsets, and non-overlapping `Count` semantics.
- Exclude: Reimplementing `Count` through another collection API.
- Cost: One DFA metadata field and one rare-path comparison.

## Verification

- Benchmark `Count` for pattern `a` over geometrically growing `a^N` inputs.
- Compare later longer matches and equal-length competing matches under both match kinds.

## Publication-Blockers

Representative measurements and upstream prior-art coverage are missing.

## Next-Action

Summary: Prototype longest-match exit
Action: Benchmark a disposable maximum-length early exit against the measured `Count` workload.
Done-When: Comparative measurements show linear scaling while all existing matching tests remain unchanged.
