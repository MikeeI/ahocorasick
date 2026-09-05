# ISSUE-008 — Build: unused pattern bitmap scans every pattern byte

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

Root-Cause [S]: DFA construction computes and retains `patternBytes`, but no production path reads it.

## Reach-and-Impact

Reach [S]: Every automaton build scans every byte of every pattern for this bitmap.
Impact [O]: The isolated bitmap loop cost 505–539 µs per MiB of pattern bytes.

## Evidence

- [S] `dfa.go:69-72` — the DFA stores the 256-bit bitmap.
- [S] `dfa.go:124-126` — construction updates it for every pattern byte.
- [S] Complete symbol references contain only the field declaration and this write.
- [O] `go test -run '^$' -bench '^BenchmarkEvidencePatternBitmapLoop$' -benchmem -benchtime=200ms -count=5` → 505–539 µs/MiB with zero allocations; Go 1.27.1, linux/amd64.

## Prior-Art

Coverage: local ledger; checked=2026-09-05.
Gaps: Upstream issues, pull requests, discussions, and releases remain unchecked.

Contribution fit: Undecided — practical build impact and prior art remain unresolved.

## Proposed-Change

Remove `patternBytes` and its inner construction loop while retaining pattern-length and start-byte collection.

## Scope-and-Constraints

- Preserve: Pattern lengths, start-byte prefiltering, byte classes, and every search result.
- Exclude: Adding a speculative consumer for the unused bitmap.
- Cost: A localized deletion with a small expected gain.

## Verification

- Benchmark builds with fixed distinct patterns and increasing duplicate pattern bytes.
- Compare all search results and start-byte prefilter metadata before and after removal.

## Publication-Blockers

Measured contribution value, upstream prior-art coverage, and a user-selected publication target are missing.

## Next-Action

Summary: Research upstream prior art
Action: Search upstream work for removal or intended use of `patternBytes`.
Done-When: Prior art determines whether deletion or restoration of a consumer is appropriate.

## Pull-Request-Implementation

Branch: `perf/issue-008-bitmap`
Base: `upstream/main@d32beb4d396e0431f487ccf734a451a145ba7c53`
Scope: Remove the unreferenced pattern bitmap and its construction pass.
Commit: `3b75845`
Push: `origin/perf/issue-008-bitmap`
Checks:

- `go test -race ./...` → passed.
- Temporary end-to-end benchmark → before and after ranges overlapped at 224–252 ms for one MiB of duplicate pattern bytes.
