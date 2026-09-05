# ISSUE-006 — Build: DFA compilation repeatedly resolves identical failure chains

State: Investigating
Authorized-Work: Not-Selected
Publication-Target: Not-Selected
External-Reference: Not published.
Contribution-Priority: Low
Root-Cause-Confidence: High
Finding-Category: Performance
Created: 2026-09-05
Updated: 2026-09-05
Source: `upstream/main@d32beb4d396e0431f487ccf734a451a145ba7c53`

## Root-Cause

Root-Cause [S]: DFA compilation independently follows the complete failure chain for every state and byte class.

## Reach-and-Impact

Reach [S]: Every automaton build executes this compilation loop.
Impact [O]: Build time rose from 97–119 µs at depth 256 to 21.8–25.2 ms at depth 4,096.

## Evidence

- [S] `dfa.go:146-155` — compilation invokes `resolveTransition` for every transition-table cell.
- [S] `dfa.go:193-202` — each invocation follows failure links until finding a transition or root.
- [S] Existing state IDs reflect insertion order and do not guarantee dependency-safe compilation order.
- [O] `go test -run '^$' -bench '^BenchmarkEvidenceBuildDeepFailure$' -benchmem -benchtime=100ms -count=3` → 16× depth increased runtime by roughly 200–260×; Go 1.27.1, linux/amd64.

## Prior-Art

Coverage: local ledger; checked=2026-09-05.
Gaps: Upstream issues, pull requests, discussions, and releases remain unchecked.

Contribution fit: Undecided — practical build impact and prior art remain unresolved.

## Proposed-Change

Compile states in breadth-first order and copy missing transitions from each already resolved failure-state row.

## Scope-and-Constraints

- Preserve: Effective transitions, embedded match flags, byte classes, and insertion-order pattern IDs.
- Exclude: Runtime search-loop changes.
- Cost: Compilation needs an explicit breadth-first state order.

## Verification

- Benchmark builds for geometrically increasing `a^L` pattern lengths.
- Compare every DFA transition across pattern insertion orders and byte-class modes.

## Publication-Blockers

Representative build measurements and upstream prior-art coverage are missing.

## Next-Action

Summary: Prototype row reuse
Action: Benchmark disposable breadth-first row reuse against the measured deep-failure workload.
Done-When: Comparative measurements approach transition-table scaling and preserve every generated transition.
