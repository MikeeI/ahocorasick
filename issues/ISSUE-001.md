# ISSUE-001 — Search: repeated start-byte scans become quadratic

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

Root-Cause [S]: `IsMatch` repeatedly scans the complete remaining haystack once per configured start byte after failed starts.

## Reach-and-Impact

Reach [S]: Every `IsMatch` call with an enabled multi-byte prefilter can reach this path.
Impact [A]: Adversarial sparse candidates can make scanned input quadratic; representative runtime impact remains unmeasured.

## Evidence

- [S] `automaton.go:193-201` — returning to root invokes the prefilter over the complete remaining suffix.
- [S] `automaton.go:210-218` — the helper calls `bytes.IndexByte` once per start byte without narrowing later scans.
- [S] Patterns `ab,z` with `(ax)^r` make the absent `z` scan suffixes totaling `r(r+1)` bytes.

## Prior-Art

Coverage: local ledger; checked=2026-09-05.
Gaps: Upstream issues, pull requests, discussions, and releases remain unchecked.

Contribution fit: Undecided — prior art and representative measurements remain required.

## Proposed-Change

Use one membership-table scan for multiple start bytes while retaining `bytes.IndexByte` for a single start byte.

## Scope-and-Constraints

- Preserve: Byte semantics, first-candidate position, binary inputs, and all match results.
- Exclude: Unrelated DFA or match-selection changes.
- Cost: The scalar multi-byte path may regress long candidate-free inputs and requires comparative benchmarks.

## Verification

- Benchmark `(ax)^r`, candidate-free haystacks, sparse candidates, and binary start bytes across growing inputs.
- Compare every returned result against the current implementation.

## Publication-Blockers

Representative measurements and upstream prior-art coverage are missing.

## Next-Action

Summary: Benchmark prefilter scaling
Action: Add a temporary benchmark comparing adversarial, sparse, and candidate-free prefilter workloads.
Done-When: Measurements establish whether one multi-byte scan improves representative and worst-case scaling.
