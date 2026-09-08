# ISSUE-003 — Build: propagated suffix matches duplicate large output lists

State: PR-Ready
Authorized-Work: Pull-Request-Implementation
Publication-Target: New-pull-request
External-Reference: Not published.
Contribution-Priority: Medium
Root-Cause-Confidence: High
Finding-Category: Performance
Created: 2026-09-05
Updated: 2026-09-08
Source: `upstream/main@787d365428bfd22a7a801fd4499515fd2d42bfd7`

## Root-Cause

Root-Cause [S]: NFA match propagation copies every inherited suffix match into each accepting state's output list.

## Reach-and-Impact

Reach [S]: Every build with suffix-related patterns performs propagation before DFA compilation.
Impact [O]: Retained allocations rose from 2.67 MB at suffix depth 32 to about 10.05 MB at depth 256.

## Evidence

- [S] `nfa.go:186-190` — each state appends its failure state's complete match list.
- [S] `dfa.go:158-175` — DFA compilation counts and copies all expanded lists again.
- [S] `dfa.go:136-153` — expanded lists also determine transition match flags.
- [O] `go test -run '^$' -bench '^BenchmarkEvidenceBuildSuffixOutputs$' -benchmem -benchtime=100ms -count=3` → allocation bytes grew 3.8× as suffix depth grew 8×; Go 1.27.1, linux/amd64.

## Prior-Art

Coverage: issues, pull requests, commits, releases, current source, external implementations, and algorithmic prior art; checked=2026-09-08.
Gaps: GitHub Discussions are not enabled for this repository.

- No exact upstream issue, pull request, commit, or release adopts output links for inherited matches.
- `https://github.com/coregx/ahocorasick/pull/2` — Related DFA architecture; it retains expanded match lists.
- `https://cp-algorithms.com/string/aho_corasick.html` — Related terminal-link algorithmic prior art.
- BurntSushi's Rust implementation also materializes inherited match lists rather than applying this correction.

Contribution fit: A new memory-focused pull request to `main`, with explicit search-throughput evidence.

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

None.

## Next-Action

Summary: Review pull request draft
Action: Present the exact current pull request draft and target for user approval.
Done-When: The user approves or requests changes to the exact draft and target.

## Pull-Request-Implementation

Branch: `perf/issue-003-output-links`
Base: `upstream/main@787d365428bfd22a7a801fd4499515fd2d42bfd7`
Scope: Store direct matches once and traverse inherited outputs through terminal links.
Commit: `55fef13d77be9e3fe5fcaf4fc39b063f82e1a04c`
Push: `origin/perf/issue-003-output-links`
Checks:

- `golangci-lint run --fix ./...` → passed with zero issues.
- `golangci-lint run ./...` → passed with zero issues.
- `go test ./...` → passed.
- `go test -race ./...` → passed.
- `go vet ./...` → passed.
- `BenchmarkBuildSuffixOutputs` → 311–375 µs/op, 63,552 B/op, 535 allocs/op.
- Current-upstream baseline → 394–442 µs/op, 336,816–336,817 B/op, 789 allocs/op.
- Existing search benchmark ranges overlap the current-upstream baseline.

## Publication-Draft

Target: `coregx/ahocorasick`, base `main`, head `MikeeI:perf/issue-003-output-links`.
Title: `perf: link inherited suffix outputs`

Body:

```markdown
## Problem

NFA construction currently appends every failure state's complete match list to each accepting descendant.
DFA construction then copies those expanded lists again into `matchData`.
Nested suffix pattern families therefore retain the same inherited pattern IDs in many states and in both representations.

## Change

- Keep only direct pattern IDs on each NFA and DFA state.
- Record the nearest terminal failure state as an output link.
- Use a first-match helper for APIs that need only one effective output.
- Traverse output links only for APIs that enumerate inherited matches.
- Preserve direct-before-inherited order, duplicate PatternIDs, and both match kinds.
- Retain the v0.3.1 `maxPatternLen` early termination behavior.

## Results

On Go 1.27.1, linux/amd64, AMD Ryzen 9 5950X, building 256 nested suffix patterns:

| Metric | Current main | Output links |
| --- | ---: | ---: |
| Time | 394–442 µs/op | 311–375 µs/op |
| Allocated bytes | 336,816–336,817 B/op | 63,552 B/op |
| Allocations | 789 allocs/op | 535 allocs/op |

Existing `Find`, `FindAll`, `IsMatch`, and `Count` benchmark ranges overlap the current-main baseline.

## Verification

- `golangci-lint run --fix ./...`
- `golangci-lint run ./...`
- `go test ./...`
- `go test -race ./...`
- `go vet ./...`
- `go test -run '^$' -bench '^Benchmark(BuildSuffixOutputs|Find|FindAll|IsMatchNoMatch|IsMatchWithMatch|CountLeftmostLongest)$' -benchmem -benchtime=200ms -count=5`

The terminal-link representation is established Aho-Corasick technique.
This change claims a Go-specific retained-memory improvement, not a novel algorithm.

### Disclosure

Investigated thoroughly with GPT-5.6 Codex (extra high reasoning effort), using [Oh My Pi](https://github.com/can1357/oh-my-pi) as the agent framework.

This report is not generic or unreviewed AI-generated output.
Its claims were checked against the cited evidence, and it includes the relevant detail intended to help maintainers resolve the issue.

If reports like this are not useful to the project, please let me know and I will refrain from submitting similar ones.
My intent is to help without wasting maintainer time or energy or discouraging their work.

Thank you for your work.
```
