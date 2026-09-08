# ISSUE-011 — Build: SetPrefilter(false) is discarded

State: PR-Ready
Authorized-Work: Pull-Request-Implementation
Publication-Target: New-pull-request
External-Reference: Not published.
Contribution-Priority: High
Root-Cause-Confidence: High
Finding-Category: Performance
Created: 2026-09-06
Updated: 2026-09-08
Source: `upstream/main@787d365428bfd22a7a801fd4499515fd2d42bfd7`

## Root-Cause

Root-Cause [S]: `Builder.Build` discards `Builder.prefilter`, so `SetPrefilter(false)` cannot disable the search prefilter.

## Reach-and-Impact

Reach [S]: `Find`, `IsMatch`, and repeated `Find` calls through `Count` use `DFA.startBytes` regardless of the setting.
Reach [S]: `coregx/coregex@575404745597ce471fff847630cd4d0d064e70aa` explicitly calls `SetPrefilter(false)`.
Impact [S]: The downstream consumer cannot select its intended DFA-only search strategy.
Impact [A]: The end-to-end performance effect in representative `coregex` workloads remains unmeasured.

## Evidence

- [S] `builder.go:Builder.prefilter` stores the setting.
- [S] `builder.go:Builder.SetPrefilter` changes only that field.
- [S] `builder.go:Builder.Build` never reads the field and calls `buildDFA` without it.
- [S] `dfa.go:buildDFA` always collects every distinct pattern start byte into `DFA.startBytes`.
- [S] `automaton.go:Automaton.Find` enables its initial prefilter whenever `startBytes` is nonempty.
- [S] `automaton.go:Automaton.IsMatch` enables initial and repeated prefiltering from the same metadata.
- [S] The relevant data flow is unchanged from the measured revision through the recorded current source.
- [O] A Go 1.23.2 characterization produced structurally identical automata for `true` and `false`.
- [O] The same characterization returned identical results on four candidate and match distributions.
- [S] `coregx/coregex/prefilter/ahocorasick.go` calls `SetPrefilter(false)` before `Build`.
- [S] `coregx/coregex/prefilter/prefilter.go` selects that implementation above `MaxTeddyPatterns`.
- [S] `MaxTeddyPatterns` equals `MaxFatTeddyPatterns`, whose value is 64.

## Prior-Art

Coverage: issues, pull requests, commits, releases, history, current downstream use, and the available discussion surface.
Checked: 2026-09-08.

- `https://github.com/coregx/ahocorasick/issues/1` — Related general prefilter performance report.
- `https://github.com/coregx/ahocorasick/pull/2` — Related origin of start-byte prefiltering.
- No exact upstream issue, pull request, commit, or release wires `SetPrefilter` into DFA construction.
- Current `coregx/coregex` still calls `SetPrefilter(false)` for Aho-Corasick prefilters.
- GitHub Discussions are not enabled for this repository.

Contribution fit: A focused configuration-contract pull request to `main`.

## Proposed-Change

Pass the configured prefilter state into DFA construction.
Leave `DFA.startBytes` empty when prefiltering is disabled.

## Scope-and-Constraints

- Preserve the default enabled state and existing enabled search path.
- Preserve match results, byte offsets, pattern IDs, match kinds, and public signatures.
- Preserve independence of built automata from later builder mutations.
- Exclude the repeated multi-start-byte algorithm tracked by `ISSUE-001`.
- Exclude removal of the unused `patternBytes` bitmap tracked by `ISSUE-008`.
- Exclude match-selection corrections tracked by `ISSUE-010`.
- Disabled prefiltering may be slower on long candidate-free inputs, as explicitly requested by the caller.

## Performance-Evidence

Measurement status: The correction is implemented and behavior-verified; end-to-end performance remains unquantified.

- [O] On a 64 KiB dense-failed-start workload, `SetPrefilter(false)` measured 264.965–284.480 µs.
- [O] On the same workload, `SetPrefilter(true)` measured 262.911–279.483 µs.
- [O] Both measurements used Go 1.23.2, linux/amd64, `GOMAXPROCS=1`, and five 100 ms repetitions.
- [S] The correction removes all start-byte prefilter metadata when disabled without adding a search-loop branch.
- [A] Its end-to-end performance magnitude in `coregex` remains unknown.

## Verification

- Verify that `false` produces no start-byte prefilter metadata.
- Verify that `true` and the default preserve the existing metadata and search path.
- Compare `Find` and `IsMatch` results with prefiltering enabled and disabled.
- Cover a long prefix so `Find` reaches its prefilter threshold.
- Run `go test ./...` and `go test -race ./...` on a supported toolchain.

## Publication-Blockers

None.

## Next-Action

Summary: Review pull request draft
Action: Present the exact current pull request draft and target for user approval.
Done-When: The user approves or requests changes to the exact draft and target.

## Pull-Request-Implementation

Branch: `fix/issue-011-prefilter-flag`
Base: `upstream/main@787d365428bfd22a7a801fd4499515fd2d42bfd7`
Scope: Propagate `Builder.prefilter` into DFA construction and omit disabled prefilter metadata.
Commit: `60619e3d2638308b78cf45bb84905f9bfdd3003f`
Push: `origin/fix/issue-011-prefilter-flag`
Checks:

- `golangci-lint run --fix ./...` → passed with zero issues.
- `golangci-lint run ./...` → passed with zero issues.
- `go test -run '^TestPrefilterConfiguration$' -count=1` → passed.
- `go test ./...` → passed.
- `go test -race ./...` → passed.
- `go vet ./...` → passed.

## Publication-Draft

Target: `coregx/ahocorasick`, base `main`, head `MikeeI:fix/issue-011-prefilter-flag`.
Title: `fix: honor SetPrefilter configuration`

Body:

```markdown
## Problem

`Builder.SetPrefilter` stores the requested value, but `Builder.Build` never reads it.
`buildDFA` therefore collects pattern start bytes regardless of whether the caller selected `SetPrefilter(false)`.
The setting cannot disable the prefilter used by `Find`, `IsMatch`, and repeated `Find` calls through `Count`.

This is exercised by `coregx/coregex`, which explicitly disables the start-byte skip for its Aho-Corasick prefilter.

## Change

- Pass the configured prefilter state into DFA construction.
- Collect start-byte metadata only when prefiltering is enabled.
- Preserve the default-enabled behavior and existing enabled search path.
- Add coverage for default, explicitly enabled, and disabled configurations.
- Confirm that enabled and disabled automatons return the same search results.

The disabled state is resolved at build time, so search loops gain no additional configuration branch.

## Verification

- `golangci-lint run --fix ./...`
- `golangci-lint run ./...`
- `go test -run '^TestPrefilterConfiguration$' -count=1`
- `go test ./...`
- `go test -race ./...`
- `go vet ./...`

Related issue #1 and PR #2 cover general prefilter performance and its initial implementation.
They do not cover the discarded `SetPrefilter` value.

### Disclosure

Investigated thoroughly with GPT-5.6 Codex (extra high reasoning effort), using [Oh My Pi](https://github.com/can1357/oh-my-pi) as the agent framework.

This report is not generic or unreviewed AI-generated output.
Its claims were checked against the cited evidence, and it includes the relevant detail intended to help maintainers resolve the issue.

If reports like this are not useful to the project, please let me know and I will refrain from submitting similar ones.
My intent is to help without wasting maintainer time or energy or discouraging their work.

Thank you for your work.
```
