# ISSUE-007 — Build: match propagation repeats the failure-link traversal

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

Root-Cause [S]: Match propagation rebuilds and traverses the same breadth-first state order used for failure links.

## Reach-and-Impact

Reach [S]: Every normal build runs both traversals sequentially.
Impact [S]: The second traversal adds `S×A` dense transition inspections and another `S`-sized queue lifecycle.

## Evidence

- [S] `nfa.go:118-158` — failure-link construction traverses all states and dense transition rows.
- [S] `nfa.go:161-194` — match propagation immediately repeats that traversal with a separate queue.
- [S] Failure targets have lower depth, so their match metadata is available during breadth-first processing.

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

Representative measurements and upstream prior-art coverage are missing.

## Next-Action

Summary: Measure duplicate traversal
Action: Profile build time and allocations attributable to both NFA breadth-first traversals.
Done-When: Measurements show whether traversal fusion has meaningful practical value.
