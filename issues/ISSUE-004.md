# ISSUE-004 — Build: overflow match lists retain duplicate backing arrays

State: Investigating
Authorized-Work: Pull-Request-Implementation
Publication-Target: Not-Selected
External-Reference: Not published.
Contribution-Priority: Medium
Root-Cause-Confidence: High
Finding-Category: Performance
Created: 2026-09-05
Updated: 2026-09-05
Source: `upstream/main@d32beb4d396e0431f487ccf734a451a145ba7c53`

## Root-Cause

Root-Cause [S]: Overflow entries retain original NFA match slices after the same IDs were copied into `matchData`.

## Reach-and-Impact

Reach [S]: Any state whose packed match count or offset exceeds `0xFFFF` enters this branch.
Impact [O]: A 65,536-entry overflow retained two separate 262,144-byte ID payloads.

## Evidence

- [S] `dfa.go:173-175` — every match list is first copied into the fully preallocated packed array.
- [S] `dfa.go:177-184` — overflow then stores the original slice instead of the packed section.
- [S] `dfa.go:206-217` — all consumers read returned slices without mutation.
- [O] `go test -run '^TestEvidenceOverflowRetention$' -v -count=1` → `matchDataBytes=262144 overflowBytes=262144`; Go 1.27.1, linux/amd64.

## Prior-Art

Coverage: local ledger; checked=2026-09-05.
Gaps: Upstream issues, pull requests, discussions, and releases remain unchecked.

Contribution fit: Undecided — retained-memory measurement and prior-art research remain required.

## Proposed-Change

Point overflow entries at capacity-limited sections of the fully preallocated `matchData` array.

## Scope-and-Constraints

- Preserve: Pattern IDs, ordering, overflow behavior, and read-only access.
- Exclude: Redesigning the complete match representation.
- Cost: A localized slice-ownership change.

## Verification

- Measure retained heap for count overflow and offset overflow cases.
- Compare all returned pattern IDs and ordering before and after the change.

## Publication-Blockers

Post-fix retained-memory measurement, upstream prior-art coverage, and a user-selected publication target are missing.

## Next-Action

Summary: Research upstream prior art
Action: Search upstream work for the same overflow-retention root cause before drafting a contribution.
Done-When: Prior art is classified and the correct publication target is known.

## Pull-Request-Implementation

Branch: `perf/issue-004-overflow`
Base: `upstream/main@d32beb4d396e0431f487ccf734a451a145ba7c53`
Scope: Back overflow entries with capacity-limited sections of packed match data.
Commit: `3c17a88`
Push: `origin/perf/issue-004-overflow`
Checks:

- `go test -race ./...` → passed.
- Focused temporary assertion → the overflow slice shares the packed `matchData` backing array.
