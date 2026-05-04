# Anti-Laziness: Mechanical Enforcement of Step Completeness

## Root Cause

Every instance of "laziness" (skipped steps, hollow execution, deferred fixes) follows the same pattern:

**Any step that produces no verifiable artifact WILL be skipped. Any artifact not checked by a downstream Gate WILL degrade in quality.**

This is not a failure of agent discipline — it is a failure of design. The orchestrator is markdown, not code. Without mechanical checks, instructions are suggestions.

## The Artifact Principle

Every step MUST produce one of:
- A **file** with a **content marker** (`<!-- STEP_X_COMPLETE -->`)
- A **content assertion** that a downstream Gate can mechanically verify (e.g., `[MISSING]=0`)

If you are designing a new step and it produces neither: **it does not exist**. It will be skipped. Add an artifact or remove the step.

## Known Laziness Patterns and Their Fixes

### Pattern 1: Skip-Because-No-File
**Symptom**: Step is described in prose but produces no file → agent executes it implicitly, inconsistently, or not at all.
**Example**: Step 3.3a "Assess Draft Needs" — no output file required → assessment was implicit, not written.
**Fix**: Every assessment/decision step MUST write its output to a named file.

### Pattern 2: Produce-But-Don't-Inject
**Symptom**: Step produces a file (e.g., deep-reads.md) but no downstream step explicitly reads and applies it.
**Example**: Round 2 deep-reads found 10 corrected metrics but only 4 were applied to the draft.
**Fix**: Every producer step MUST have a corresponding consumer step. The consumer step MUST produce a verification marker.

### Pattern 3: Audit-Without-Application
**Symptom**: Audit/correction report is written (e.g., fact-check, citation audit) but corrections are not applied to the draft before the next phase.
**Example**: Phase 6 found Dice overstatement — not fixed until Phase 7R, after reviewers all flagged it.
**Fix**: Gate Layer 1 checks that corrections were APPLIED, not just that the audit file EXISTS.

### Pattern 4: Partial-Execution-By-Default
**Symptom**: Instruction says "do N things" (e.g., "top-5 papers") but N is a suggestion, not a Gate requirement.
**Example**: Citation chaining searched 3+2 instead of 5+5.
**Fix**: Replace open-ended numbers with structured selection criteria + minimum counts verified by content assertions.

### Pattern 5: Deferred-Verification
**Symptom**: Verification step (e.g., Regression Check) is at the end of a long sequence → skipped because the agent is near context limit.
**Example**: Phase 7R Step 4.5 Regression Check never executed.
**Fix**: Move verification to the earliest possible point. Add intermediate checkpoints.

## Gate Layer 1 Content Assertions

File existence alone is insufficient. The following content assertions MUST also pass:

| Gate | File | Content Assertion |
|------|------|-------------------|
| GATE 2 | phase3-deep-reads.md | Contains `### Paper` headers (≥1, indicating actual content) |
| GATE 2 | phase3-citation-audit.md | Contains `[MISSING]=0` or `[MISSING]: 0` |
| GATE 2 | phase3-deep-read-injection.md | EXISTS (proves deep-read findings were applied to draft) |
| GATE 3 | phase6-corrections-applied.md | EXISTS (proves Phase 6 corrections were applied to draft before Phase 7) |
| GATE 4 | phase7-revision-plan.md | Contains issue categories (FACT/CITATION/STRUCTURE/CONTENT/LANGUAGE/DATA) |
| GATE 5 | phase8-style-check.md | Contains "HTML comment markers removed" confirmation |

## The Consumer-Producer Chain

Every file produced by one step MUST be explicitly consumed by a later step. This table makes the chain visible:

| Producer Step | Output File | Consumer Step | How Consumed |
|---------------|-------------|---------------|--------------|
| 3.3b Deep Reads | phase3-deep-reads.md | 3.5 Step 0 (Deep Read Injection) | Read findings → apply to draft → write injection report |
| 3.4 Agent B | phase3-citation-audit.md | 3.5 Step 2 (Citation Fixes) | Read [MISSING] items → add citations → mark resolved |
| 3.4 Agent C | phase3-data-licensing-audit.md | 3.5 Step 3 (Data Notes) | Read [UNVERIFIED-DATASET] → add caveats to draft |
| 6 Fact-Check | phase6-factcheck.md | 6.5 Correction Application | Read corrections → apply to draft → write applied report |
| 6 Fact-Check | phase6-corrections-applied.md | GATE 3 | Verify file exists before proceeding to Phase 7 |

**If a consumer is missing from this chain, the producer's output WILL be ignored.** Add the consumer or remove the producer.

## Step Completion Markers

Every sub-step that produces a file MUST end with a completion marker as the LAST line:

```
<!-- STEP_X_COMPLETE: YYYY-MM-DD -->
```

The absence of this marker on a non-empty file indicates the file may be truncated (interrupted mid-write by compaction). The producing step must be re-run.

## Agent Self-Audit Checklist

Before passing ANY gate, the agent MUST verify:

```
□ Every file in the Consumer-Producer Chain for this phase has been both produced AND consumed
□ No [MISSING] or [UNVERIFIED] flags remain unresolved in citation audits
□ Fact-check corrections have been applied AND verified (phase6-corrections-applied.md exists)
□ Deep-read findings have been injected into the draft (phase3-deep-read-injection.md exists)
□ Completion markers are present on all output files
□ No step with a file output requirement was executed "implicitly" without writing the file
```

**If the answer to any item is NO: do NOT pass the gate. Return to the incomplete step.**

## Why This Works

This file encodes in prose what the orchestrator cannot encode in code:
- **Traceability**: Every step leaves a verifiable trace
- **Consumption**: Every artifact has a designated consumer
- **Early detection**: Gate Layer 1 catches missing steps BEFORE the next phase begins
- **No trust required**: The agent doesn't need to "remember" — the files remember

The artifact principle transforms aspirational instructions ("read deeply and apply findings") into mechanical requirements ("produce phase3-deep-read-injection.md or GATE 2 fails").
