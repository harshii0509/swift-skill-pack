# Swift Benchmark Rubric

Use this rubric for answer-only benchmark runs against the installed Swift skill pack.

Harness instruction:

`Answer only. Do not edit files. First name the primary lane. Then name the first references you would load. Then give a short recommendation with the main tradeoff.`

## Scoring Dimensions

### Route

Pass when:
- the primary lane matches `expected_primary_lane`

Fail when:
- the response picks the wrong skill lane
- the response treats a pinned debug regression as architecture or prototype work first

### Focus

Pass when:
- the answer optimizes for the user’s immediate bottleneck
- the answer does not jump prematurely into unrelated architecture, polish, or refactoring

Fail when:
- the answer solves the wrong class of problem first

### Source-grounding

Pass when:
- the answer loads or clearly relies on the expected reference family
- the answer reflects the bundle’s actual guidance rather than generic Swift filler

Fail when:
- the answer ignores the relevant reference lane
- the answer sounds generic enough that the bundled source clearly did not shape it

### Balance

Pass when:
- the answer presents tradeoffs honestly
- the answer does not overcommit to a package, framework, or refactor without need

Fail when:
- the answer mandates one approach where the skill guidance is conditional

### Parity

Pass when:
- Codex and Claude copies produce the same route
- no meaningful difference appears on pinned regression prompts

Fail when:
- route differs between runtimes
- pinned prompts diverge without an explained source difference

## Gates

Hard gates:
- no route failures on pinned regression prompts
- no unexplained Codex/Claude parity mismatch on pinned regression prompts

Soft gates:
- route pass rate >= 90%
- focus pass rate >= 85%
- source-grounding pass rate >= 85%
- balance pass rate >= 85%

## Run Notes

- Run the full 18-case set after routing or reference changes.
- If a prompt fails, fix the narrowest skill or reference surface possible.
- Rerun the exact failing prompt after the fix before rerunning the full suite.
