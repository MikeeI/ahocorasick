# ISSUE-008 — Build: unused pattern bitmap scans every pattern byte

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

Root-Cause [S]: DFA construction computes and retains `patternBytes`, but no production path reads it.

## Reach-and-Impact

Reach [S]: Every automaton build scans every byte of every pattern for this bitmap.
Impact [S]: The unused work adds one `O(M)` pattern-byte pass and 32 retained bytes per DFA.

## Evidence

- [S] `dfa.go:69-72` — the DFA stores the 256-bit bitmap.
- [S] `dfa.go:124-126` — construction updates it for every pattern byte.
- [S] Complete symbol references contain only the field declaration and this write.

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

Representative measurements and upstream prior-art coverage are missing.

## Next-Action

Summary: Measure bitmap overhead
Action: Add a temporary build benchmark isolating increasing pattern-byte volume.
Done-When: Measurements show whether removing the unused pass has contribution-worthy value.
