# ISSUE-003 — Build: propagated suffix matches duplicate large output lists

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

Root-Cause [S]: NFA match propagation copies every inherited suffix match into each accepting state's output list.

## Reach-and-Impact

Reach [S]: Every build with suffix-related patterns performs propagation before DFA compilation.
Impact [S]: Patterns `a^1…a^256,a^65536` produce 16,744,577 packed IDs, or 66,978,308 payload bytes.

## Evidence

- [S] `nfa.go:186-190` — each state appends its failure state's complete match list.
- [S] `dfa.go:158-175` — DFA compilation counts and copies all expanded lists again.
- [S] `dfa.go:136-153` — expanded lists also determine transition match flags.

## Prior-Art

Coverage: local ledger; checked=2026-09-05.
Gaps: Upstream issues, pull requests, discussions, and releases remain unchecked.

Contribution fit: Undecided — a complete representation design and measurements remain required.

## Proposed-Change

Store direct matches once, link inherited outputs, precompute the effective first match, and derive flags from direct or inherited matches.

## Scope-and-Constraints

- Preserve: Match flags, first-match access, output order, duplicate patterns, overlaps, and both match kinds.
- Exclude: Lazy work on the per-byte transition path.
- Cost: Central match representation and four search consumers change together.

## Verification

- Compare all search APIs for patterns `b,abx` over `ab` and nested suffix families.
- Measure retained heap, build time, and search throughput for increasing suffix depth.

## Publication-Blockers

A complete constant-time first-match design, representative measurements, and upstream prior art are missing.

## Next-Action

Summary: Prototype output links
Action: Design and benchmark a disposable linked-output representation without changing tracked source.
Done-When: The prototype preserves all search results and improves retained memory without material throughput loss.
