# ISSUE-001 — Search: repeated start-byte scans become quadratic

State: PR-Ready
Authorized-Work: Pull-Request-Implementation
Publication-Target: New-pull-request
External-Reference: Not published.
Contribution-Priority: High
Root-Cause-Confidence: High
Finding-Category: Performance
Created: 2026-09-05
Updated: 2026-09-08
Source: `upstream/main@787d365428bfd22a7a801fd4499515fd2d42bfd7`

## Root-Cause

Root-Cause [S]: `IsMatch` repeatedly scans the complete remaining haystack once per configured start byte after failed starts.

## Reach-and-Impact

Reach [S]: Every `IsMatch` call with an enabled multi-byte prefilter can reach this path.
Impact [O]: Runtime rose from 7.1–9.6 µs at 1,024 bytes to 13.2–14.5 ms at 65,536 bytes.

## Evidence

- [S] `automaton.go:193-201` — returning to root invokes the prefilter over the complete remaining suffix.
- [S] `automaton.go:210-218` — the helper calls `bytes.IndexByte` once per start byte without narrowing later scans.
- [S] Patterns `ab,z` with `(ax)^r` make the absent `z` scan suffixes totaling `r(r+1)` bytes.
- [O] `go test -run '^$' -bench '^BenchmarkEvidenceIsMatchRepeatedPrefilter$' -benchmem -benchtime=100ms -count=3` → 64× input increased runtime by roughly 1,500–2,000×; Go 1.27.1, linux/amd64, Ryzen 9 5950X.

## Prior-Art

Coverage: issues, pull requests, commits, releases, current source, and the available discussion surface; checked=2026-09-08.
Gaps: GitHub Discussions are not enabled for this repository.

- `https://github.com/coregx/ahocorasick/issues/1` — Related general prefilter performance report, not this root cause.
- `https://github.com/coregx/ahocorasick/pull/2` — Related origin of the repeated start-byte prefilter.
- No exact upstream issue, pull request, commit, or release fixes repeated suffix scans.
- Rust Aho-Corasick tracks scan progress to avoid revisiting already scanned input.

Contribution fit: A new pull request to `main` with adversarial ordering coverage.

## Proposed-Change

Keep SIMD byte searches for the initial scan and use one membership-table pass for every repeated multi-byte scan.

## Scope-and-Constraints

- Preserve: Byte semantics, first-candidate position, binary inputs, and all match results.
- Exclude: Unrelated DFA or match-selection changes.
- Cost: One 256-bit mask per DFA; repeated multi-byte scans use a scalar membership loop.

## Verification

- Benchmark `(ax)^r`, candidate-free haystacks, sparse candidates, and binary start bytes across growing inputs.
- Compare every returned result against the current implementation.

## Publication-Blockers

None.

## Next-Action

Summary: Review pull request draft
Action: Present the exact current pull request draft and target for user approval.
Done-When: The user approves or requests changes to the exact draft and target.

## Pull-Request-Implementation

Branch: `perf/issue-001-prefilter`
Base: `upstream/main@787d365428bfd22a7a801fd4499515fd2d42bfd7`
Scope: Prevent repeated multi-byte prefilter scans from revisiting each remaining suffix.
Commit: `adb41644a02cdaadd8001af5d89eb868ad79aaf8`
Push: `origin/perf/issue-001-prefilter`
Checks:

- `golangci-lint run --fix ./...` → passed with zero issues.
- `golangci-lint run ./...` → passed with zero issues.
- `go test ./...` → passed.
- `go test -race ./...` → passed.
- `go vet ./...` → passed.
- `BenchmarkIsMatchRepeatedPrefilter` → 133–149 µs/op for both start-byte orders, 0 B/op, 0 allocs/op.
- Candidate-free baseline and correction ranges overlapped at 2.95–3.28 µs/op.

## Publication-Draft

Target: `coregx/ahocorasick`, base `main`, head `MikeeI:perf/issue-001-prefilter`.
Title: `perf: prevent repeated multi-byte prefilter scans`

Body:

```markdown
## Problem

`IsMatch` re-engages the start-byte prefilter whenever the DFA returns to its start state.
The current helper runs one `bytes.IndexByte` over the complete remaining suffix for every configured start byte.
Frequent failed starts can therefore make the same suffix participate in many complete scans.

The existing optimization is also sensitive to start-byte order.
If an absent byte sorts before a frequent candidate, that absent byte scans the entire remaining suffix on every retry.

## Change

- Keep bounded `bytes.IndexByte` searches for the one-time initial prefilter scan.
- Precompute a 256-bit start-byte membership mask during DFA construction.
- Use one membership-table pass for repeated scans with multiple start bytes.
- Retain `bytes.IndexByte` for the single-start-byte path.
- Add adversarial benchmarks and coverage for both start-byte orders.

## Results

On Go 1.27.1, linux/amd64, AMD Ryzen 9 5950X:

| Workload | Before | After |
| --- | ---: | ---: |
| 64 KiB repeated failed starts, present byte first | 13.2–14.5 ms/op | 139–145 µs/op |
| 64 KiB repeated failed starts, absent byte first | quadratic by control flow | 133–149 µs/op |
| 64 KiB candidate-free control | 2.95–3.08 µs/op | 3.00–3.28 µs/op |

All measured paths report zero allocations.
The candidate-free ranges overlap, while both repeated-scan orderings complete in the same linear range.

## Verification

- `golangci-lint run --fix ./...`
- `golangci-lint run ./...`
- `go test ./...`
- `go test -race ./...`
- `go vet ./...`
- `go test -run '^$' -bench '^BenchmarkIsMatch(RepeatedPrefilter|NoMatch|WithMatch)$' -benchmem -benchtime=200ms -count=5`

Related issue #1 and PR #2 introduced and measured the general start-byte prefilter.
They do not cover repeated suffix scans or adversarial start-byte ordering.

### Disclosure

Investigated thoroughly with GPT-5.6 Codex (extra high reasoning effort), using [Oh My Pi](https://github.com/can1357/oh-my-pi) as the agent framework.

This report is not generic or unreviewed AI-generated output.
Its claims were checked against the cited evidence, and it includes the relevant detail intended to help maintainers resolve the issue.

If reports like this are not useful to the project, please let me know and I will refrain from submitting similar ones.
My intent is to help without wasting maintainer time or energy or discouraging their work.

Thank you for your work.
```
