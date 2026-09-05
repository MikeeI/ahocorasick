# project-ahocorasick-fork

<essential-rule>
AGENTS.md is the sole authoritative project context file.
Read and edit AGENTS.md directly.
</essential-rule>

## Development Rules

Before launching agents, apply skill-xray, skill-expert, and skill-brutal to the task.
Surface expert-level issues, non-obvious issues, blindspots, stale assumptions, and hidden dependencies.
Also surface missed constraints, edge cases, false positives, verification gaps, overclaims, and weak assumptions.
Identify improvement potential, inefficiencies, and what is wrong without softening.
Use these findings to design safe slices, sequencing, checks, and boundaries for complete agent results.

Every agent prompt must require skill-xray, skill-expert, and skill-brutal for the assigned scope before acting.
It must surface non-obvious issues, blindspots, stale assumptions, hidden dependencies, and edge cases.
It must also surface verification gaps, overclaims, failure modes, weak assumptions, and what is wrong.
The agent must adjust its approach, challenge its assumptions, and flag misleading or incomplete output risks.

Implementation assignments must cover existing patterns, callers, exported-symbol consumers, and failure modes.
They must also cover concurrency safety and lifecycle cleanup.
Each assignment must state `Test decision: none` or `Test decision: update`.
`update` must name the exact existing test that follows an intentional contract change.
Never request new tests.
Prohibit broad edits, unrelated cleanup, and unassigned files.

No vague agents.
Each assignment needs exact targets, non-goals, evidence anchors, acceptance criteria, and an output contract.

Commit completed units continuously.
Before each commit, use skill-git-commit-format to determine whether staged effects are one coherent unit.
The skill owns commit-message format and evidence.
After the boundary is valid, run the repository-owned commit and push workflow.
Do not commit every trivial edit immediately or defer unrelated work into one end-of-session commit.

Every project-level quality command is quiet by default and verbose on demand.
This policy applies regardless of language or toolchain.
It covers Make targets, package scripts, Python CLIs, shell quality gates, and test runners.
Successful checks print only compact status such as `format: ok`, `lint: ok`, `test: ok`, or `check: ok`.
On failure, exit non-zero and print the failing step, exit code, and enough output to act without rerunning.
Full raw output must remain available through `--verbose`, `VERBOSE=1`, or the underlying tool's verbose mode.
New quality commands and future language setup must follow this policy instead of inventing another logging contract.

# Repository Guidelines

## Project Overview

`ahocorasick` is a pure-Go Aho-Corasick multi-pattern byte matcher with no external dependencies.
The module remains `github.com/coregx/ahocorasick`; this fork preserves upstream package identity.

## Fork & Upstream Contribution Intent

- Official upstream: [coregx/ahocorasick](https://github.com/coregx/ahocorasick).
- This checkout is the [MikeeI/ahocorasick](https://github.com/MikeeI/ahocorasick) fork, not an independently owned product.
- The goal is to support upstream with evidence-backed issues, comments, and pull requests.
- `ISSUES.md` provides the compact finding overview and global ID allocator.
- `issues/ISSUE-NNN.md` owns the complete durable record for one root cause.
- `FORMAT.md` owns research, drafting, implementation authorization, approval, and publication rules.
- Prefer small, well-scoped corrections with outsized maintainer or user value.
- Recommend a pull request when a bounded verified fix is ready and no active implementation owns it.
- Otherwise recommend a comment, a new issue, or continued investigation according to the evidence.
- Apply `skill-fork-contribution-tracking` for ledger, lifecycle, personal-branch, and upstream handoff work.
- Apply `skill-maintainer-communication` before external issues, pull requests, reviews, comments, or discussions.
- Search existing work first and follow current upstream templates and disclosure rules.
- Apply `skill-semantic-compression-3` when authoring or restructuring tracking content.
- Apply `skill-git-commit-format` while respecting explicit upstream contribution conventions.
- Never choose `Authorized-Work` or `Publication-Target` on the user's behalf.
- `Research-and-Reporting` permits research, issues, and comments but no source implementation.
- `Pull-Request-Implementation` authorizes only the scoped implementation recorded for that finding.
- Base upstream contribution branches on current `upstream/main`.
- Keep fork-only context, ledgers, configuration, and personal commits out of upstream contribution diffs.
- Reproduce claimed bugs against current upstream and run the narrowest conclusive verification.
- Publish one coherent root cause per issue, comment, or pull request.

## Finding and Contribution Ledger

- At the start of every agent session, agents MUST read root `ISSUES.md` before repository work.
- `ISSUES.md` owns the global `Next finding ID` allocator and compact cross-finding overview.
- Each `issues/ISSUE-NNN.md` owns one finding's state, evidence, drafts, and next action.
- `FORMAT.md` is authoritative for research, drafting, implementation boundaries, and publication format.
- Before adding a finding, search the index and every relevant issue record for the same symptom or root cause.
- New findings MUST use `Next finding ID`.
- Create the issue file, add its index row, and increment the allocator together.
- Finding IDs use `ISSUE-NNN`, start at `ISSUE-001`, and remain permanent.
- Never reuse, renumber, or scope IDs by subsystem, status, session, or contribution type.
- Update the issue file and `ISSUES.md` together after state, authorization, target, priority, next action, or reference changes.
- Every issue record MUST use the field and section contract in `FORMAT.md`.
- New findings start with `State: Investigating`, `Authorized-Work: Not-Selected`, and `Publication-Target: Not-Selected`.
- New findings use `External-Reference: Not published.` until an external reference exists.
- Keep findings Investigating until currentness, prior art, impact, and correction value are evidence-backed.
- Clone detectors, AST matches, text similarity, shared names, and TODOs produce candidates only.
- A duplication finding requires shared change pressure, realistic drift, and simpler consolidation.
- The user selects `Authorized-Work` for each finding.
- `Research-and-Reporting` MUST NOT implement the finding.
- `Pull-Request-Implementation` MAY implement only the recorded scope after research resolves callers and failure modes.
- Pull-request work MUST verify behavior, commit, push, and reach `PR-Ready` before publication.
- Show the exact draft and target before publishing an issue, comment, or pull request to official upstream.
- Publish to official upstream only after the user approves the exact current draft and target.
- Any draft or target change requires showing the complete current draft and target again before publication.
- Run the read-only validator bundled with `skill-fork-contribution-tracking` after every ledger mutation.
- Record the final external URL in `External-Reference` immediately after publication.
- Keep `FORMAT.md`, `ISSUES.md`, `issues/`, and fork-only `AGENTS.md` changes out of upstream contribution diffs.

### External publication approval

Only an external issue, comment, review, discussion, or pull request write is approval-gated.
Before publication, read current contribution guidance and explain applicable project policy.
The human must be able to review and own every submission statement.
Fork commits, pushes, tracking updates, and source implementation follow the active repository contract.

## Branch Roles

- `origin` is `git@github.com:MikeeI/ahocorasick.git`; `upstream` is `git@github.com:coregx/ahocorasick.git`.
- `personal` owns fork guidance and tracking and tracks `origin/personal`.
- Keep `main` source-only; create clean contribution worktrees from the current upstream base.
- At initialization, upstream defaults to `main` and exposes no `develop` branch.
- `CONTRIBUTING.md` requests `develop` for feature PRs; resolve that mismatch before external publication.

## Architecture & Data Flow

- `Builder.Build` validates nonempty patterns, builds byte classes, constructs an NFA, and compiles a flat DFA.
- `nfa.go` owns trie construction, failure links, and match propagation.
- `dfa.go` owns compiled transitions and premultiplied state IDs.
- `automaton.go` owns search, start-byte prefiltering, overlapping search, counting, and pattern accessors.
- `byteclasses.go` owns alphabet compression; `match.go` owns match offsets and match-kind definitions.
- Preserve byte offsets, insertion-order pattern IDs, and LeftmostFirst versus LeftmostLongest semantics.
- Upstream documents concurrent automaton reuse; inspect pattern-slice ownership before relying on immutability.
- Upstream throughput figures are workload-specific claims, not measurements from this fork setup.

## Key Directories

- Root Go files contain the single library package and its tests, fuzz targets, and benchmarks.
- `.github/workflows/` owns CI; `scripts/` contains upstream release validation.
- `issues/` stores open findings; `issues/archive/` stores archived findings.

## Development Commands

- Build with `go build ./...` and run unit tests with `go test ./...`.
- Run race checks with `go test -race ./...` and static checks with `go vet ./...`.
- Format changed Go code with `go fmt ./...`; run the configured linter with `golangci-lint run`.
- Benchmark with `go test -bench=. -benchmem ./...`; the documented `simd/` and `prefilter/` packages do not exist here.
- Upstream release validation is `bash scripts/pre-release-check.sh` and includes a mutating `go mod tidy` step.

## Code Conventions

- Preserve upstream package layout, exported API, Go formatting, and Conventional Commit conventions.
- Keep search hot paths allocation-conscious and document non-obvious DFA and prefilter invariants.
- Consult `CONTRIBUTING.md` before contribution work and `SECURITY.md` before vulnerability disclosure.

## Important Files

- `go.mod` owns module identity and the Go version; `.golangci.yml` owns linter configuration.
- `README.md` owns public usage examples; `CHANGELOG.md` owns release history.
- Preserve upstream `LICENSE`, contribution guidance, and security policy.

## Runtime/Tooling Preferences

- `go.mod` requires Go 1.25.4; do not substitute the release script's older version threshold.
- Keep the pure-Go, zero-external-dependency build and upstream tooling rather than adding project scaffolding.

## Testing & QA

- `ahocorasick_test.go` owns unit tests, `FuzzIsMatch`, `FuzzFind`, and search benchmarks.
- Cover matching semantics, byte-class behavior, offsets, overlaps, Unicode bytes, and binary inputs when affected.
- Performance-critical contributions require representative benchmarks under upstream contribution policy.
- CI exercises Linux, macOS, Windows, race detection, and Linux 386 builds and tests.
