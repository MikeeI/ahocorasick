# ISSUE-002 — Search: maximal match still scans the remaining haystack

State: PR-Ready
Authorized-Work: Pull-Request-Implementation
Publication-Target: New-pull-request
External-Reference: Not published.
Contribution-Priority: High
Root-Cause-Confidence: High
Finding-Category: Performance
Created: 2026-09-05
Updated: 2026-09-05
Source: `upstream/main@d32beb4d396e0431f487ccf734a451a145ba7c53`

## Root-Cause

Root-Cause [S]: `Find` under `LeftmostLongest` keeps scanning after finding a match that no pattern can exceed.

## Reach-and-Impact

Reach [S]: `Find` reaches the path directly; `Count` repeatedly invokes it from successive match ends.
Impact [O]: Runtime rose from 126–144 µs at 256 bytes to 8.12–8.81 ms at 2,048 bytes.

## Evidence

- [S] `automaton.go:74-82` — only `LeftmostFirst` returns immediately after a match.
- [S] `automaton.go:321-335` — `Count` invokes `Find` for every non-overlapping match.
- [S] `dfa.go:116-127` — all pattern lengths are already available during compilation.
- [O] `go test -run '^$' -bench '^BenchmarkEvidenceCountLongest$' -benchmem -benchtime=100ms -count=3` → 8× input increased runtime by roughly 60×; Go 1.27.1, linux/amd64, Ryzen 9 5950X.

## Prior-Art
Coverage: issues(open+closed), PRs(open+closed+merged), commits, contribution guidance, and PR template; checked=2026-09-05.
Gaps: GitHub Discussions and release search expose no dedicated repository search surface.

- `https://github.com/coregx/ahocorasick/issues/1` — Related; it optimized general DFA and prefilter throughput, not `LeftmostLongest` termination.
- Exact searches for `LeftmostLongest`, `Count performance`, and `maximum pattern length` found no duplicate issue or pull request.

Contribution fit: New pull request to `main` — the documented `develop` target does not exist on the upstream remote.

## Proposed-Change

Store the maximum compiled pattern length and return once `Find` has a match of that length.

## Scope-and-Constraints

- Preserve: Leftmost ordering, equal-length tie behavior, offsets, and non-overlapping `Count` semantics.
- Exclude: Reimplementing `Count` through another collection API.
- Cost: One DFA metadata field and one rare-path comparison.

## Verification

- Benchmark `Count` for pattern `a` over geometrically growing `a^N` inputs.
- Compare later longer matches and equal-length competing matches under both match kinds.

## Publication-Blockers

None.

## Next-Action

Summary: Await publication approval
Action: Show the exact pull request target and draft to the user.
Done-When: The user approves the current target and complete draft without changes.

## Pull-Request-Implementation

Branch: `perf/issue-002-max-match`
Base: `upstream/main@d32beb4d396e0431f487ccf734a451a145ba7c53`
Scope: Stop `LeftmostLongest` search after finding a maximum-length pattern.
Commit: `70f1e50`
Push: `origin/perf/issue-002-max-match`
Checks:

- `go test -race ./...` → passed.
- Temporary benchmark → `Count` fell from 8.12–8.81 ms to 31.9–35.0 µs at 2,048 bytes.
- `golangci-lint run` → passed with zero issues.
- `go test ./...` → passed.
- `BenchmarkCountLeftmostLongest` → 30.1–33.4 µs/op, 0 B/op, and 0 allocs/op.

## Publication-Draft

Target: `coregx/ahocorasick`, base `main`, head `MikeeI:perf/issue-002-max-match`.
Title: `perf: stop LeftmostLongest at maximum pattern length`

Body:

```markdown
## Problem

`Find` with `LeftmostLongest` continues scanning after finding a match whose length equals the longest compiled pattern.
No later match can be strictly longer, so the remaining scan cannot replace that result under the current selection rule.
`Count` amplifies this work because it repeatedly calls `Find` from each previous match end.

In a dense single-byte match workload using pattern `a` and a 2,048-byte `a` haystack, the previous implementation took 8.12–8.81 ms per `Count` call.

## Change

- Record the maximum pattern length while the DFA already collects pattern lengths.
- Return from `Find` once the best match reaches that maximum.
- Add `BenchmarkCountLeftmostLongest` for the dense-match workload.

The early return preserves the current strictly-longer replacement rule.
Once a selected match reaches the maximum compiled pattern length, no later match can replace it.

## Results

On Go 1.27.1, linux/amd64, AMD Ryzen 9 5950X:

| Workload | Before | After |
| --- | ---: | ---: |
| `Count`, pattern `a`, 2,048-byte `a` haystack | 8.12–8.81 ms/op | 30.1–33.4 µs/op |

This is a deliberately dense single-byte worst case for repeated `LeftmostLongest` searches.
It demonstrates the eliminated quadratic path rather than general `Count` throughput.

The committed benchmark reports zero allocations.

## Verification

- `golangci-lint run`
- `go test ./...`
- `go test -race ./...`
- `go test -run '^$' -bench '^BenchmarkCountLeftmostLongest$' -benchmem -benchtime=200ms -count=5`

Related issue #1 addressed general DFA and start-byte-prefilter throughput.
It did not cover this `LeftmostLongest` termination path.

### Disclosure

Investigated thoroughly with GPT-5.6 Codex (extra high reasoning effort), using [Oh My Pi](https://github.com/can1357/oh-my-pi) as the agent framework.

This report is not generic or unreviewed AI-generated output.
Its claims were checked against the cited evidence, and it includes the relevant detail intended to help maintainers resolve the issue.

If reports like this are not useful to the project, please let me know and I will refrain from submitting similar ones.
My intent is to help without wasting maintainer time or energy or discouraging their work.

Thank you for your work.
```
