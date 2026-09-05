# ISSUE-005 — Search: anchored misses scan beyond every possible match

State: Investigating
Authorized-Work: Not-Selected
Publication-Target: Not-Selected
External-Reference: Not published.
Contribution-Priority: Medium
Root-Cause-Confidence: High
Finding-Category: Performance
Created: 2026-09-05
Updated: 2026-09-05
Source: `upstream/main@d32beb4d396e0431f487ccf734a451a145ba7c53`

## Root-Cause

Root-Cause [S]: `FindAt` can continue past the maximum pattern length when failure transitions avoid the root state.

## Reach-and-Impact

Reach [S]: Every unsuccessful anchored lookup with such a failure cycle reaches this path.
Impact [O]: Runtime rose from 1.48–1.88 µs at 1,024 bytes to 93–107 µs at 65,536 bytes.

## Evidence

- [S] `automaton.go:107-145` — scanning stops on a root-state condition, not a pattern-length bound.
- [S] Pattern `aab` keeps repeated `a` bytes in the state representing prefix `aa`.
- [S] `automaton.go:126-127` discards later starts but does not stop further scanning.
- [O] `go test -run '^$' -bench '^BenchmarkEvidenceFindAtMiss$' -benchmem -benchtime=100ms -count=3` → runtime scaled linearly with 64× input despite a three-byte maximum pattern; Go 1.27.1, linux/amd64.

## Prior-Art

Coverage: local ledger; checked=2026-09-05.
Gaps: Upstream issues, pull requests, discussions, and releases remain unchecked.

Contribution fit: Undecided — measurement and prior-art research remain required.

## Proposed-Change

Limit anchored scanning to the remaining haystack or the maximum compiled pattern length, whichever is shorter.

## Scope-and-Constraints

- Preserve: Exact-start semantics, match ordering, offsets, and both match kinds.
- Exclude: Changes to unanchored search behavior.
- Cost: Reuse the maximum-length metadata proposed by ISSUE-002.

## Verification

- Benchmark unsuccessful `FindAt` calls for `aab` over geometrically growing `a^N` inputs.
- Compare successful matches ending exactly at the maximum length under both match kinds.

## Publication-Blockers

Representative measurements and upstream prior-art coverage are missing.

## Next-Action

Summary: Prototype anchored bound
Action: Benchmark a disposable maximum-length bound against the measured anchored-miss workload.
Done-When: Runtime becomes input-length independent beyond the bound and matching tests remain unchanged.
