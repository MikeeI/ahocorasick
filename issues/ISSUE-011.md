# ISSUE-011 — Build: SetPrefilter(false) is discarded

State: Investigating
Authorized-Work: Not-Selected
Publication-Target: Not-Selected
External-Reference: Not published.
Contribution-Priority: High
Root-Cause-Confidence: High
Finding-Category: Performance
Created: 2026-09-06
Updated: 2026-09-06
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

Coverage: upstream issues and pull requests for `SetPrefilter`, disabled prefiltering, start bytes, and `FindAll`.
Checked: 2026-09-06.

- https://github.com/coregx/ahocorasick/issues/1 — Related; introduced the general performance requirement.
- https://github.com/coregx/ahocorasick/pull/2 — Related; introduced the DFA and start-byte prefilter.
- https://github.com/coregx/ahocorasick/issues/7 — Not duplicate; concerns allocations from `Find` return values.
- https://github.com/coregx/ahocorasick/pull/8 — Not duplicate; implements the zero-allocation API change.
- https://github.com/coregx/ahocorasick/pull/10 — Not duplicate; bounds `LeftmostLongest` search termination.
- No upstream issue or pull request was found for the discarded `SetPrefilter` value.

Contribution fit: A bounded pull request is plausible after current-toolchain verification and user authorization.

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

Measurement status: The ignored setting is proven, but no implemented correction has been benchmarked.

- [O] On a 64 KiB dense-failed-start workload, `SetPrefilter(false)` measured 264.965–284.480 µs.
- [O] On the same workload, `SetPrefilter(true)` measured 262.911–279.483 µs.
- [O] Both measurements used Go 1.23.2, linux/amd64, `GOMAXPROCS=1`, and five 100 ms repetitions.
- [A] A correction should remove unwanted skip-search work when prefiltering is disabled.
- [A] Its magnitude under Go 1.25.4 or newer and in `coregex` remains unknown.

## Verification

- Verify that `false` produces no start-byte prefilter metadata.
- Verify that `true` and the default preserve the existing metadata and search path.
- Compare every public search result with prefiltering enabled and disabled.
- Cover both match kinds, byte classes enabled and disabled, binary data, overlaps, and nonzero starts.
- Benchmark candidate-free, sparse-candidate, and dense-failed-start workloads before and after correction.
- Benchmark the downstream selection class with more than 64 literals of minimum length 3.
- Run `go test ./...` and `go test -race ./...` on a supported toolchain.

## Publication-Blockers

Current supported-toolchain correction measurements, user-selected authorization, and a publication target are missing.

## Next-Action

Summary: Reproduce supported-toolchain baseline
Action: Reproduce the characterization and representative workloads on current upstream with Go 1.25.4 or newer.
Done-When: The setting remains ineffective and stable baseline ranges are recorded on a supported toolchain.
