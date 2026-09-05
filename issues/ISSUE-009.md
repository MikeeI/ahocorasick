# ISSUE-009 — Build: large byte alphabets wrap the class counter

State: Investigating
Authorized-Work: Pull-Request-Implementation
Publication-Target: Not-Selected
External-Reference: Not published.
Contribution-Priority: High
Root-Cause-Confidence: High
Finding-Category: Correctness
Created: 2026-09-05
Updated: 2026-09-05
Source: `upstream/main@d32beb4d396e0431f487ccf734a451a145ba7c53`

## Root-Cause

Root-Cause [O]: `NewByteClasses` uses a byte counter that wraps while assigning 255 or 256 used byte values.

## Reach-and-Impact

Reach [S]: Default `Builder.Build` reaches this path when patterns collectively contain at least 255 distinct bytes.
Impact [O]: A single pattern containing all 256 byte values makes `Build` panic instead of returning an automaton or error.

## Evidence

- [S] `byteclasses.go:33-42` — class assignment increments a `byte` and converts the wrapped result to `numClasses`.
- [S] With 255 used bytes, the counter wraps to zero; with 256 used bytes, it wraps and assigns class zero again.
- [O] `go test -run '^TestEvidenceAllByteClassesPanic$' -v -count=1` → recovered `runtime error: index out of range [1] with length 1`; Go 1.27.1, linux/amd64.

## Prior-Art

Coverage: local ledger; checked=2026-09-05.
Gaps: Upstream issues, pull requests, discussions, and releases remain unchecked.

Contribution fit: Undecided — upstream prior-art research remains required.

## Proposed-Change

Count classes with `int`; return singleton byte classes when all 256 byte values are used.

## Scope-and-Constraints

- Preserve: Class zero for unused bytes, compact classes for smaller alphabets, and identity mapping for a full alphabet.
- Exclude: Redesigning byte-class equivalence or search semantics.
- Cost: One localized construction fix and regression coverage for 255 and 256 distinct bytes.

## Verification

- Build and search automata containing exactly 254, 255, and 256 distinct byte values.
- Run the complete existing test suite after the focused regression cases.

## Publication-Blockers

Upstream prior-art coverage and a user-selected publication target are missing.

## Next-Action

Summary: Research upstream prior art
Action: Search upstream work for the same class-counter overflow before drafting a contribution.
Done-When: Prior art is classified and the correct publication target is known.

## Pull-Request-Implementation

Branch: `fix/issue-009-byte-classes`
Base: `upstream/main@d32beb4d396e0431f487ccf734a451a145ba7c53`
Scope: Prevent class-counter wrap for 255 and 256 distinct byte values.
Commit: `3ae54d8`
Push: `origin/fix/issue-009-byte-classes`
Checks:

- `go test -run '^TestByteClasses(LargeAlphabet)?$' -count=1` → passed.
- `go test ./...` → passed.
