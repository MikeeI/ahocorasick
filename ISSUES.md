# Issue and Pull Request Tracking

Read this index at the start of every agent session before repository work.
`FORMAT.md` owns research, lifecycle, drafting, implementation, and publication rules.
Each linked `issues/ISSUE-NNN.md` is the complete authoritative record for one root cause.
This file owns `Next finding ID` and projects current issue-file state.
`Next-Action` is the 2–6 word `Next-Action/Summary` projection from the issue record.
When a row disagrees with its issue file, correct the row from the issue file in the same task.

Next finding ID: ISSUE-010

## Open-Findings

| ID | Finding | State | Authorized-Work | Publication-Target | Contribution-Priority | Next-Action | External-Reference |
| --- | --- | --- | --- | --- | --- | --- | --- |
| [ISSUE-001](issues/ISSUE-001.md) | Search: repeated start-byte scans become quadratic | Investigating | Not-Selected | Not-Selected | High | Prototype prefilter fix | Not published. |
| [ISSUE-002](issues/ISSUE-002.md) | Search: maximal match still scans the remaining haystack | Investigating | Not-Selected | Not-Selected | High | Prototype longest-match exit | Not published. |
| [ISSUE-003](issues/ISSUE-003.md) | Build: propagated suffix matches duplicate large output lists | Investigating | Not-Selected | Not-Selected | Medium | Prototype output links | Not published. |
| [ISSUE-004](issues/ISSUE-004.md) | Build: overflow match lists retain duplicate backing arrays | Investigating | Not-Selected | Not-Selected | Medium | Verify packed overflow slice | Not published. |
| [ISSUE-005](issues/ISSUE-005.md) | Search: anchored misses scan beyond every possible match | Investigating | Not-Selected | Not-Selected | Medium | Prototype anchored bound | Not published. |
| [ISSUE-006](issues/ISSUE-006.md) | Build: DFA compilation repeatedly resolves identical failure chains | Investigating | Not-Selected | Not-Selected | Low | Prototype row reuse | Not published. |
| [ISSUE-007](issues/ISSUE-007.md) | Build: match propagation repeats the failure-link traversal | Investigating | Not-Selected | Not-Selected | Low | Prototype traversal fusion | Not published. |
| [ISSUE-008](issues/ISSUE-008.md) | Build: unused pattern bitmap scans every pattern byte | Investigating | Not-Selected | Not-Selected | Low | Compare bitmap removal | Not published. |
| [ISSUE-009](issues/ISSUE-009.md) | Build: large byte alphabets wrap the class counter | Investigating | Not-Selected | Not-Selected | High | Research byte-class panic | Not published. |

## Archived-Findings

| ID | Finding | Authorized-Work | Publication-Target | Contribution-Priority | Archive-Reason | External-Reference |
| --- | --- | --- | --- | --- | --- | --- |