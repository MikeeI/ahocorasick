# ISSUE-009 — Build: large byte alphabets wrap the class counter

State: PR-Ready
Authorized-Work: Pull-Request-Implementation
Publication-Target: New-pull-request
External-Reference: Not published.
Contribution-Priority: High
Root-Cause-Confidence: High
Finding-Category: Correctness
Created: 2026-09-05
Updated: 2026-09-08
Source: `upstream/main@787d365428bfd22a7a801fd4499515fd2d42bfd7`

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

Coverage: issues, pull requests, commits, releases, file history, current source, and the available discussion surface; checked=2026-09-08.
Gaps: GitHub Discussions are not enabled for this repository.

- No upstream issue, pull request, commit, or release fixes the 255-byte or 256-byte boundary.
- The canonical `byteclasses.go` history contains only the original affected implementation.
- Released v0.3.1 retains the same byte-valued counter.

Contribution fit: A focused correctness pull request to `main`.

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

None.

## Next-Action

Summary: Review pull request draft
Action: Present the exact current pull request draft and target for user approval.
Done-When: The user approves or requests changes to the exact draft and target.

## Pull-Request-Implementation

Branch: `fix/issue-009-byte-classes`
Base: `upstream/main@787d365428bfd22a7a801fd4499515fd2d42bfd7`
Scope: Prevent class-counter wrap for 255 and 256 distinct byte values.
Commit: `c4e9f821ef7394260e7ca8876c222f1211a14d50`
Push: `origin/fix/issue-009-byte-classes`
Checks:

- `golangci-lint run --fix ./...` → passed with zero issues.
- `golangci-lint run ./...` → passed with zero issues.
- `go test -run '^TestByteClasses(LargeAlphabet)?$' -count=1` → passed.
- `go test ./...` → passed.
- `go test -race ./...` → passed.
- `go vet ./...` → passed.

## Publication-Draft

Target: `coregx/ahocorasick`, base `main`, head `MikeeI:fix/issue-009-byte-classes`.
Title: `fix: handle full byte alphabets`

Body:

```markdown
## Problem

`NewByteClasses` assigns used-byte classes with a `byte` counter starting at one.
The counter wraps after 255 used byte values.

With 255 distinct bytes, `NumClasses` becomes zero while positive class IDs remain in the mapping.
With all 256 bytes, the final byte also collides with class zero.
`Builder.Build` then allocates invalid transition rows and panics while indexing them.

## Change

- Count distinct bytes and class IDs with `int`.
- Preserve compact class IDs while at least one byte remains unused.
- Use singleton identity classes when all 256 byte values occur.
- Cover the 254, 255, and 256 distinct-byte boundaries through the public build and search APIs.

## Verification

- `golangci-lint run --fix ./...`
- `golangci-lint run ./...`
- `go test -run '^TestByteClasses(LargeAlphabet)?$' -count=1`
- `go test ./...`
- `go test -race ./...`
- `go vet ./...`

The change preserves class zero for unused bytes and uses identity mapping only for the full alphabet.

### Disclosure

Investigated thoroughly with GPT-5.6 Codex (extra high reasoning effort), using [Oh My Pi](https://github.com/can1357/oh-my-pi) as the agent framework.

This report is not generic or unreviewed AI-generated output.
Its claims were checked against the cited evidence, and it includes the relevant detail intended to help maintainers resolve the issue.

If reports like this are not useful to the project, please let me know and I will refrain from submitting similar ones.
My intent is to help without wasting maintainer time or energy or discouraging their work.

Thank you for your work.
```
