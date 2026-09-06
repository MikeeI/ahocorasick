# ISSUE-012 — Search: aggregate APIs scan impossible initial prefixes

State: Investigating
Authorized-Work: Not-Selected
Publication-Target: Not-Selected
External-Reference: Not published.
Contribution-Priority: Medium
Root-Cause-Confidence: High
Finding-Category: Performance
Created: 2026-09-06
Updated: 2026-09-06
Source: `upstream/main@787d365428bfd22a7a801fd4499515fd2d42bfd7`

## Root-Cause

Root-Cause [S]: `FindAll` and `FindAllOverlapping` do not skip prefixes containing no possible pattern start byte.

## Reach-and-Impact

Reach [S]: Every call to either aggregate API starts DFA traversal at byte zero.
Reach [S]: With one distinct pattern start byte, an absent byte proves that no match can begin in the scanned region.
Impact [O]: Long synthetic prefixes spend substantially more time in aggregate DFA traversal than `Find`.
Impact [A]: The frequency and end-to-end cost of this input shape in real aggregate-search consumers remain unknown.

## Evidence

- [S] `automaton.go:Automaton.FindAll` starts traversal at index zero without reading `DFA.startBytes`.
- [S] `automaton.go:Automaton.FindAllOverlapping` does the same.
- [S] `automaton.go:Automaton.Find` already performs an initial start-byte skip for at least 128 remaining bytes.
- [S] Patterns `ERROR` and `EXCEPTION` have exactly one distinct start byte, `E`.
- [S] A prefix without `E` cannot contain the start of either pattern.
- [S] The relevant aggregate-search paths are unchanged from the measured revision through the recorded current source.
- [O] Negative benchmark cases returned no matches and allocated zero bytes in all compared methods.
- [O] At 64 KiB, medians were 0.7221 µs for `Find` and 125.287 µs for `FindAll`.
- [O] At 64 KiB, `FindAllOverlapping` measured a 132.752 µs median.
- [O] At 1 MiB, medians were 13.877 µs, 1,930.901 µs, and 2,079.242 µs respectively.
- [O] The measurements used Go 1.23.2, linux/amd64, `GOMAXPROCS=1`, and five 100 ms repetitions.
- [S] These API comparisons expose avoidable DFA work but do not measure an implemented correction.

## Prior-Art

Coverage: upstream issues and pull requests for `FindAll`, prefiltering, start bytes, and skip-ahead search.
Checked: 2026-09-06.

- https://github.com/coregx/ahocorasick/issues/1 — Related; requests faster multi-pattern search and start-state optimization.
- https://github.com/coregx/ahocorasick/pull/2 — Related; added the DFA, prefiltering, and inline `FindAll` loop.
- https://github.com/coregx/ahocorasick/pull/2 — Its `FindAll` benchmark uses a short, match-dense input.
- https://github.com/coregx/ahocorasick/pull/10 — Not duplicate; bounds `LeftmostLongest` termination.
- No upstream issue or pull request was found for an initial aggregate-search start-byte skip.

Contribution fit: Undecided until representative reach and a correction comparison establish High ROI.

## Proposed-Change

For one distinct start byte and a sufficiently long input, find the first possible start before each aggregate DFA loop.
Return the existing empty result if the byte is absent.
Otherwise, begin the unchanged DFA traversal at the resulting absolute offset.

## Scope-and-Constraints

- Preserve `nil` for empty result sets.
- Preserve absolute byte offsets, pattern IDs, result order, overlap behavior, and public signatures.
- Preserve the configured prefilter-disabled state once `ISSUE-011` is corrected.
- Handle `FindAll` with `n == 0` before performing the additional scan.
- Exclude prefilter re-engagement after later returns to the start state.
- Exclude multiple start bytes and a general adaptive prefilter.
- Exclude match-selection corrections tracked by `ISSUE-010`.
- The additional scan may regress short inputs or inputs whose first possible start is near byte zero.

## Performance-Evidence

Measurement status: The missing fast path is proven, but no correction or representative consumer impact is measured.

- [O] The negative workload shows a large existing-API time difference without result-allocation differences.
- [O] A 64 KiB variant with one terminal match measured 128.211 µs for `FindAll`.
- [O] The corresponding `FindAllOverlapping` median was 126.278 µs.
- [O] Both aggregate methods allocated 24 bytes once for the terminal result.
- [O] Dense failed starts showed that repeated prefilter re-engagement can regress performance.
- [A] One initial single-byte skip should reduce work on long impossible prefixes.
- [A] The 128-byte threshold from `Find` is a conservative candidate, not a measured optimum.

## Verification

- Compare complete ordered match lists before and after the correction.
- Cover no match, a match at byte zero, one initial failed start, and a match at the end.
- Cover dense and sparse start bytes and long prefixes without the start byte.
- Cover input lengths 127, 128, and 129.
- Cover `FindAll` with `n` equal to 0, 1, 2, and -1.
- Cover both match kinds, byte classes enabled and disabled, binary input, and suffix-derived overlapping matches.
- Benchmark the proposed path on Go 1.25.4 or newer with longer repetitions.
- Reject the change if negative workloads lack stable gains or positive controls show a material regression.
- Run `go test ./...` and `go test -race ./...` on a supported toolchain.

## Publication-Blockers

Representative consumer evidence, a correction comparison, user authorization, and a publication target are missing.

## Next-Action

Summary: Validate representative workload
Action: Identify current aggregate-search consumers and reproduce the absent-prefix workload on a supported toolchain.
Done-When: Reach is characterized and stable baseline ranges exist for representative and adversarial cases.
