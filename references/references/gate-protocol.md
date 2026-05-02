## Workflow Enforcement

Skills are guidance, not code. The agent can skip phases unless the design MAKES skipping detectable. Three mechanisms prevent silent phase-skipping:

### 1. Gate Protocol (MUST follow — no exceptions)

At EVERY gate, the agent MUST:
- **Stop all forward progress.** Do not write any substantive file for the next phase.
- **Present the gate output** to the user with `AskUserQuestion` or a clear text summary followed by an explicit question.
- **Wait for explicit confirmation** — "continue", "proceed", "yes" — before doing ANY phase work. "Looks good" or silence is NOT confirmation.
- **Record the gate passage** in `research-output/phaseN-gate-N.md` (one line: "GATE N passed: [timestamp]").

If the agent catches itself summarizing results and skipping a gate — STOP. Return to the gate.

### 2. Phase State Tracking

Before starting ANY phase, check `research-output/` for the expected output of the PREVIOUS phase:
- Phase 3 expects phase2-merged.md to exist
- Phase 3.4 (refinement) expects phase3-deep-reads.md to exist (Round 2 enforcement)
- Phase 6 expects phase3-draft.md to exist
- Phase 7 expects phase6-factcheck.md to exist

If the previous phase's output is missing, the agent MUST NOT proceed. It must go back and complete the missing phase.

After completing each phase, write `research-output/.phase-state` AND append a completion marker as the LAST line of the phase's primary output file:
```
<!-- PHASE_X_COMPLETE: YYYY-MM-DD -->
```
This marker is the integrity check: if a file is missing its marker, the file may be truncated (e.g., interrupted by compaction mid-write) and the phase must be re-run.

After completing each phase, write `research-output/.phase-state`:
```
Phase 1: done
Phase 2: done
Phase 2.4: done
Phase 3: done
GATE 2: passed
...
```

This file is the single source of truth for "where are we in the pipeline."

### 3. Gate Violation Recovery

If the agent realizes it skipped a gate (e.g., summarized Phase 6 and moved toward Phase 8 without GATE 3):
1. **Stop immediately.**
2. **Read `.phase-state`** to find the last completed gate.
3. **Re-present the skipped gate** to the user.
4. Only proceed after explicit confirmation.

