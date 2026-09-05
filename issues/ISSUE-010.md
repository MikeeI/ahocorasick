# ISSUE-010 — Search: LeftmostLongest selects later or shorter matches

State: Investigating
Authorized-Work: Not-Selected
Publication-Target: Not-Selected
External-Reference: Not published.
Contribution-Priority: High
Root-Cause-Confidence: High
Finding-Category: Correctness
Created: 2026-09-05
Updated: 2026-09-05
Source: `upstream/main@d32beb4d396e0431f487ccf734a451a145ba7c53`

## Root-Cause

Root-Cause [O]: Search APIs apply length or insertion order without first preserving the earliest match start.

## Reach-and-Impact

Reach [S]: `Find`, `Count`, and non-overlapping `FindAll` expose the affected `LeftmostLongest` behavior.
Impact [O]: `Find` can select a later start, while `FindAll` can select a shorter match at the earliest start.

## Evidence

- [S] `match.go:13-16` — `LeftmostLongest` promises the longest match among matches at the same position.
- [S] `automaton.go:78-81` — `Find` replaces the current result solely when a later match is longer.
- [S] `automaton.go:260-276` — `FindAll` always accepts the first match at the earliest ending position.
- [O] Patterns `a,bbbb` over `abbbb` made `Find` return `PatternID=1 Start=1 End=5`; Go 1.27.1, linux/amd64.
- [O] Patterns `a,ab` over `ab` made `FindAll` return `PatternID=0 Start=0 End=1`; Go 1.27.1, linux/amd64.

## Prior-Art

Coverage: issues(open+closed), PRs(open+closed+merged), and commits; checked=2026-09-05.
Gaps: GitHub Discussions and releases remain unchecked.

- Exact searches for `LeftmostLongest semantics leftmost longest later match` found no issue or pull request.
- `https://github.com/coregx/ahocorasick/commit/d50ff36f8a8911332087fac6e1aef10d8954eb98` — Related; introduced the semantics without resolving these cross-position cases.

Contribution fit: Undecided — affected APIs, compatibility expectations, and the smallest shared correction need full investigation.

## Proposed-Change

Compare match starts before lengths in `Find`; make non-overlapping `FindAll` use the same selected-match semantics.

## Scope-and-Constraints

- Preserve: `LeftmostFirst`, offsets, insertion-order ties, overlap enumeration, binary inputs, and zero-allocation scalar search.
- Exclude: Combining this correctness change with the submitted performance PR.
- Cost: `FindAll` may need a shared selection primitive without adding hot-path allocations or rescans.

## Verification

- Cover later-longer, same-start-longer, equal-length tie, suffix-derived, and repeated non-overlapping matches.
- Compare `Find`, `FindAt`, `FindAll`, and `Count` for both match kinds.
- Run fuzzing and the complete race-enabled test suite after implementation.

## Publication-Blockers

Complete API impact analysis, compatibility evidence, authorization, and a publication target are missing.

## Next-Action

Summary: Map LeftmostLongest APIs
Action: Establish the intended selection contract and affected behavior across every public search API.
Done-When: One bounded correction preserves all unaffected match semantics and has exact regression cases.
