# ISSUE-007 — Build: match propagation repeats the failure-link traversal

State: Investigating
Authorized-Work: Pull-Request-Implementation
Publication-Target: Not-Selected
External-Reference: Not published.
Contribution-Priority: Low
Root-Cause-Confidence: High
Finding-Category: Performance
Created: 2026-09-05
Updated: 2026-09-05
Source: `upstream/main@d32beb4d396e0431f487ccf734a451a145ba7c53`

## Root-Cause

Root-Cause [S]: Match propagation rebuilds and traverses the same breadth-first state order used for failure links.

## Reach-and-Impact

Reach [S]: Every normal build runs both traversals sequentially.
Impact [O]: Isolated propagation over 4,096 two-byte patterns cost 505–610 µs and allocated 18,432 bytes.

## Evidence

- [S] `nfa.go:118-158` — failure-link construction traverses all states and dense transition rows.
- [S] `nfa.go:161-194` — match propagation immediately repeats that traversal with a separate queue.
- [S] Failure targets have lower depth, so their match metadata is available during breadth-first processing.
- [O] `go test -run '^$' -bench '^BenchmarkEvidencePropagateMatches$' -benchmem -benchtime=200ms -count=5` → 505–610 µs/op, 18,432 B/op, one allocation; Go 1.27.1, linux/amd64.

## Prior-Art

Coverage: local ledger; checked=2026-09-05.
Gaps: Upstream issues, pull requests, discussions, and releases remain unchecked.

Contribution fit: Undecided — practical build impact and prior art remain unresolved.

## Proposed-Change

Propagate match metadata while consuming the existing failure-link breadth-first queue.

## Scope-and-Constraints

- Preserve: Direct-before-inherited order, duplicate patterns, match flags, and both match kinds.
- Exclude: Changing the match representation unless ISSUE-003 is separately authorized.
- Cost: Failure-link construction assumes responsibility for ordered match propagation.

## Verification

- Measure build time and allocations across fixed state counts and varied alphabet sizes.
- Compare complete direct and inherited match ordering for nested suffix patterns.

## Publication-Blockers

Upstream prior-art coverage and a user-selected publication target are missing.

## Next-Action

Summary: Research upstream prior art
Action: Search upstream work for fused failure and output propagation before drafting a contribution.
Done-When: Prior art is classified and the correct publication target is known.

## Pull-Request-Implementation

Branch: `perf/issue-007-propagation`
Base: `upstream/main@d32beb4d396e0431f487ccf734a451a145ba7c53`
Scope: Propagate matches while consuming the existing failure-link queue.
Commit: `1444fc4`
Push: `origin/perf/issue-007-propagation`
Checks:

- `go test -race ./...` → passed.
- Temporary benchmark → build changed from 7.22–8.83 ms to 6.65–7.18 ms for 4,096 patterns.
- Temporary benchmark → allocation fell from about 9.83 MB to 9.82 MB and removed one allocation.
