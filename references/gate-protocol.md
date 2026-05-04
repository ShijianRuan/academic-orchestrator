## Workflow Enforcement

Skills are guidance, not code. The agent can skip phases unless the design MAKES skipping detectable. Three mechanisms prevent silent phase-skipping:

### 1. Gate Protocol — Two Independent Layers

Every gate has two layers. Layer 1 is MECHANICAL and NEVER skippable. Layer 2 is USER-FACING and can be auto-executed when the user requests it.

#### Layer 1: Mechanical Completion Check (NEVER skipped — no exceptions)

**Run the validation script first**: Before manually checking files, run `scripts/validate.sh <GATE> <research-output/>`. This catches all file-existence and content-pattern checks in one pass. Then fix any FAIL items, re-run, and proceed only when the script exits 0.

The agent MUST then verify the following (script covers most, but agent confirms):
- **GATE 1** (Phase 1→2): `phase1-plan.md` exists. ADDITIONALLY: `phase2-citation-chaining.md` (Step 2.4 completion log) is NOT a GATE 1 check (it's produced during Phase 2), but its ABSENCE at GATE 2 will block that gate.
- **GATE 2** (Phase 3→Session 2): `phase2-merged.md`, `phase3-draft-v1.md`, `phase3-deep-reads.md`, `phase3-citation-audit.md`, `phase3-data-licensing-audit.md`, `phase3-deep-read-injection.md` ALL exist. ADDITIONALLY: (a) Read `phase3-citation-audit.md` — if [MISSING] > 0 or [UNVERIFIED-SOURCE] > 0 → return to Phase 3.5 to fix citations. GATE 2 cannot pass with uncited claims or unverified references. (b) Read `phase3-deep-reads.md` — must contain `### Paper` headers (≥1, indicating actual content, not placeholder). (c) `phase3-deep-read-injection.md` MUST exist — this proves deep-read findings were explicitly applied to the draft before refinement. If missing → go back to Phase 3.5 Step 0 (Deep Read Injection).
- **GATE 3** (Phase 6→7): `phase6-factcheck.md` exists. ADDITIONALLY: `phase6-corrections-applied.md` MUST exist — this proves Phase 6 corrections were explicitly applied to the draft BEFORE peer review. If only `phase6-factcheck.md` exists but `phase6-corrections-applied.md` does not → return to Phase 6 to apply corrections. Peer review must review the corrected draft, not the draft with known errors.
- **GATE 4** (Phase 7→8): reviewer files + merged review exist. ADDITIONALLY: `phase7-revision-plan.md` MUST exist (Phase 7R output). If missing → run Phase 7R (read `references/post-review.md`) before passing.
- **GATE 5** (Phase 8→delivery): `VERIFICATION_STATUS.md` + `phase8-style-check.md` + `<!-- PHASE_8_COMPLETE -->` in references.bib MUST exist. If missing → complete Phase 8.

If the previous phase's output is missing, the agent MUST NOT proceed. It must go back and complete the missing phase. **This check runs regardless of execution mode.** Auto-execute only affects whether the user is asked for confirmation — it never skips work.

#### Layer 2: User Confirmation (can be auto-executed)

In **normal mode**, at every gate the agent MUST:
- **Stop all forward progress.** Do not write any substantive file for the next phase.
- **Present the gate output** to the user with `AskUserQuestion` or a clear text summary followed by an explicit question.
- **Wait for explicit confirmation** — "continue", "proceed", "yes" — before doing ANY phase work. "Looks good" or silence is NOT confirmation.
- **Record the gate passage** in `research-output/phaseN-gate-N.md`.

In **auto-execute mode** (user explicitly requests no interruptions):
- The agent writes a log entry: "GATE N auto-passed: [timestamp]" in `research-output/phaseN-gate-N.md`.
- The agent proceeds without asking the user.
- **Layer 1 checks STILL RUN.** If a required file is missing, the agent goes back and completes the producing step — no user interaction needed, but no step is skipped.

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


### 4. Gate Summary Format (user-facing)

Every gate presentation must follow this format. Keep it concise — the user should understand the decision in 10 seconds:

```
── GATE N: [Name] ──

[N] claims verified. [N] issues found. [N] errors corrected.
Confidence: [HIGH/MEDIUM/LOW]

[Proceed] / [Review details]
```

**What to include**: Only metrics that inform the decision at THIS gate.
- GATE 1: strategy, research questions, agents to launch
- GATE 2: word count, reference count, Round 2 papers read, citation audit results, data audit summary
- GATE 3: claims verified/unverified/contradicted, overall confidence, corrections applied
- GATE 4: reviewer recommendations, consensus issues count, scores matrix
- GATE 5: final deliverables list, caveats remaining

**What to exclude**: File paths, token counts, internal process descriptions, version numbers.
