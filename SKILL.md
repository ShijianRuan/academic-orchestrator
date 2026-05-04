---
name: academic-orchestrator
description: >
  Multi-phase academic research and writing orchestrator. Chains deep-research,
  academic-researcher, medical-imaging-review, citation-management, latex-paper-en,
  fact-check, and peer-review into a single quality-gated pipeline. Use when the user
  wants to produce a full academic paper, survey, or literature review with verified
  claims, proper citations, and submission-ready output. Triggers on: "write a paper",
  "produce a survey", "academic review", "write a review paper", "publishable review",
  "systematic review with verification", or explicit requests to use the orchestrator.
license: MIT
metadata:
  author: custom
  domain: academic
  cluster: orchestration
  type: workflow
  mode: multi-pass
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - WebSearch
  - WebFetch
  - Task
  - Agent
  - Skill
  - AskUserQuestion
---

# Academic Orchestrator

Multi-phase orchestrator for academic research and writing. Does NOT do research or writing itself — delegates each phase to the appropriate specialist skill, enforces quality gates, and persists all intermediate artifacts to disk.

**Critical design decision**: The full 8-phase pipeline exceeds a single Claude Code session's context budget. The pipeline is split across **3 sessions** bridged by files on disk, regardless of output format.

## How to Use This File

This is the **Hub**. It gives you the architecture, routing, and gate positions.
When you start a phase, **Read the corresponding reference file** for detailed instructions:

> Before starting Phase N, read `references/phase{N}-*.md`.
> Do NOT pre-read reference files for future phases. Only load what you need now.

**Gate enforcement is mechanical, not manual.** At every gate, before presenting results to the user, run:

```bash
bash scripts/validate.sh <GATE> research-output/
```

Script exit 0 = proceed. Exit non-0 = fix all FAIL items first, re-run, repeat until clean. This is NOT optional — it replaces manual Layer 1 file checking. The script catches what human attention misses.

Supporting protocols (compaction recovery, quality heuristics, post-review revision, gate enforcement, anti-laziness) are also in `references/` — load them when the relevant situation arises, not upfront.

---

## Scripts

The orchestrator ships with a mechanical validation script:

```
scripts/validate.sh <GATE> <research-output-dir>
```

Run this at EVERY gate before manual Layer 1 checks. It catches:
- Missing files, empty files, content-pattern violations
- Phase-state topological consistency, completion marker audit, cross-reference counts
- All 5 gates + phase state + markers + crossref (use `all`)

Exit 0 = mechanical checks pass. Exit non-0 = fix FAIL items, re-run.

---

## Architecture

Two paths diverge at Phase 1. RESEARCH-ONLY is single-session. Full pipeline is 3-session.

### RESEARCH-ONLY Path (Single Session)
```
Phase 1  SCOPE    → Clarify + route to RESEARCH-ONLY
GATE 1: Confirm research plan
Phase 2  RESEARCH → Parallel multi-source (Agent x 3, bg) → Merge → Citation chaining
Phase R  OUTPUT   → Digest + lightweight self-check
GATE R: Review digest
Output: research-output/research-digest.md
```

### Full Pipeline (3 Sessions)
```
SESSION 1
  Phase 1  SCOPE → Clarify + route + MCP check
  GATE 1: Confirm plan
  Phase 2  RESEARCH → Parallel multi-source (Agent x 4, bg) → Merge → Citation chaining
  Phase 3  DRAFT → Round 1 structure reads → Structural draft → Round 2 detail reads
                   (MANDATORY) → Parallel refinement → Merge
  GATE 2: Review draft
  END SESSION 1

SESSION 2
  Phase 4  CITATIONS → .bib + DOI validation + retraction check
  Phase 5  FORMAT → [FULL: LaTeX] [Markdown-only: skipped]
  END SESSION 2

SESSION 3
  Phase 6  VERIFY → Fact-check + adversarial verification
  GATE 3: Review verification
  Phase 7  REVIEW → 3 parallel peer reviewers → merge consensus
  GATE 4: Review consensus
  Phase 7R POST-REVIEW → Structured revision (dispatch protocol)
  Phase 8  FINAL → Language polish + final output
  GATE 5: Final sign-off
```

---

## Communication Protocol

The orchestrator handles two separate audiences. Do not mix them.

### What the User Sees

**Phase transitions** — consistent format at every phase start and end:
```
━━━ Phase N: [Name] ━━━
  [1-line summary of what's starting]
━━━ Phase N Complete ━━━
  [Key metrics: count, size, confidence level, errors found]
```

**Progress updates** — during long phases (Phase 2 agents, Phase 7 reviewers):
```
[N/M agents complete...]
```

**Gate summaries** — concise decision block with relevant metrics:
```
── GATE N: [Name] ──
  [3-5 key metrics]
  [Proceed] / [Review]
```

### What the User Does NOT See

The orchestrator processes these silently — they never appear in user-facing output:
- Raw agent completion notifications (token counts, tool calls, duration, buddy comments)
- File write confirmations ("File created at: ...")
- Internal file paths
- .phase-state file contents
- Version numbers or changelog text

The orchestrator reads agent outputs, extracts the relevant information, and presents only the summary metrics to the user. Internal operational details stay internal.

---

## Skill Dispatch Matrix

### RESEARCH-ONLY Path
| Phase | Method | Notes |
|-------|--------|-------|
| 1 | Agent directly + AskUserQuestion | Clarify scope |
| 2 | Agent (bg, parallel) x 3 + S2 MCP | Full parallel search |
| R | Agent directly + Write | Digest generation |

### Full Pipeline
| Phase | Method | Notes |
|-------|--------|-------|
| 1 | Agent directly + AskUserQuestion + Skill(literature-review) | Scope protocol + feasibility probe + scope boundary (literature-review Skill invoked in Step 1.4) |
| 2 | Agent (bg, parallel) x 4 + S2 MCP | Full parallel search + Paper Lookup + citation chaining + PRISMA flow documentation (Step 2.3a). Prompt includes §2 RQs + §4 Search Strategy + §6 MCP status from phase1-plan |
| 3.1 | MCP + WebFetch | Round 1 structure reads |
| 3.2 | Skill (medical-imaging-review) | Structural draft |
| 3.3 | Agent (bg, parallel) x 2 | Round 2 detail reads (MANDATORY) |
| 3.4 | Agent (bg, parallel) x 3 | Prose + Citation + Data audit |
| 3.5 | Main session | Merge refinements (incl. Deep Read Injection) |
| 3.6 | gh + WebFetch (opt) | Code repository audit |
| 3.7 | WebFetch (opt) | Figure/table extraction |
| 4 | Skill (citation-management) | BibTeX + retraction + existence verification + severity-graded validation report (Step 4.3) |
| 5 | Skill (latex-paper-en) | LaTeX conversion (FULL only) |
| 6 | Skill (fact-check) + Skill (scientific-critical-thinking) | Verification + GRADE/evidence-quality audit |
| 7 | Agent (bg, parallel) x 4 | 4 peer reviewers (Methodologist + Domain + Editor + K-Dense Peer Review) |
| 7.5 | Skill (scholar-evaluation) | Post-review quantitative scoring (8-dimension ScholarEval) — MANDATORY |
| 8 | Agent (bg) + Skill (citation-management) | Language polish + final .bib validation |

---

## Context Management

### File Disposal Rules (MANDATORY)

To prevent context exhaustion, dispose of these files from working memory at the specified checkpoints:

| Checkpoint | Dispose from Memory | Recovery Method |
|-----------|-------------------|-----------------|
| After Phase 2.3 merge | phase2-deep-research.md, phase2-academic-researcher.md, phase2-medical-imaging.md, phase2-paper-lookup.md | Read from disk if needed |
| After Phase 3 draft complete | phase2-merged.md | Read from disk if needed |
| Session 3 startup | Do NOT load phase2-merged.md or Phase 2 agent files | Phase 6 only needs draft + references.bib |

**Rule**: If a file is on disk and a later phase MIGHT need it, don't keep it in memory. Read it on demand.

### Compaction Recovery

See `references/compaction.md` for full recovery protocol.

**Quick reference**:
- Between phases: ideal. Files have `<!-- PHASE_X_COMPLETE -->` markers.
- Mid-phase with progress markers: resume from first item WITHOUT a marker.
- Mid-phase without markers (<10 items): re-run from scratch.

### Session Token Budgets (soft reference)

| Session | Phases | Typical Range |
|---------|--------|--------------|
| 1 | 1, 2, 3 | 35-55K |
| 2 | 4, [5] | 15-25K |
| 3 | 6, 7, 8 | 20-40K (unchanged) |

---

## Gates (Quick Reference)

Each gate has TWO independent layers:
- **Layer 1 (MECHANICAL)**: File dependency checks. **NEVER skipped**, regardless of execution mode.
- **Layer 2 (USER-FACING)**: AskUserQuestion confirmation. Can be auto-executed.

Gate details: Read `references/gate-protocol.md` at the first gate you encounter.

| Gate | When | Layer 1 (never skipped) | Layer 2 (normal mode) |
|------|------|------------------------------|----------------------|
| GATE 1 | Phase 1 → 2 | phase1-plan.md exists + Scope Boundary + Search Strategy + Quality Target + MCP probe results | Plan confirmed |
| GATE 2 | Phase 3 → S2 | draft + deep-reads + audits + deep-read-injection. [MISSING]=0, [UNVERIFIED-SOURCE]=0 | Draft reviewed |
| GATE 3 | Phase 6 → 7 | phase6-factcheck.md + phase6-corrections-applied.md + phase4-validation.md exist | Fact-check reviewed |
| GATE 4 | Phase 7 → rev | reviewer files + merged + revision-plan + scholar-eval exist | Consensus + revision plan |
| GATE 5 | Phase 8 → deliv | VERIFICATION_STATUS.md + phase8-style-check.md + PHASE_8_COMPLETE | Final sign-off |

### Auto-Execute Mode

When the user says "auto-execute" or "don't ask for confirmation":
- Layer 2 (user prompts) is skipped. Agent logs "GATE N auto-passed" and proceeds.
- **Layer 1 (file checks) STILL RUNS.** If a required file is missing, agent goes back and completes the producing step — no user interaction needed, but no step is ever skipped.
- Auto-execute = "don't ask me." It does NOT mean "skip work."

`.phase-state` file tracks all progress. Completion markers on output files verify integrity.

---

## Quick Start

```
# Session 1 — Research + Draft
/academic-orchestrator
"Use the academic orchestrator to write a survey paper on [topic]"

# Session 2 — Citations
/academic-orchestrator
"continue from Phase 4"

# Session 3 — Verify + Review + Final
/academic-orchestrator
"continue from Phase 6"
```

All intermediate files are in `research-output/`. Each session reads what it needs from disk.

**Markdown-only output**: At Phase 1, say "Markdown only, skip LaTeX." Phase 5 is skipped.

---

## Reference Files

Load these when needed, not upfront:

| File | When to Load |
|------|-------------|
| `references/anti-laziness.md` | **Before Phase 1** (mandatory pre-read) |
| `references/phase1-scope.md` | Phase 1 |
| `references/phase2-research.md` | Phase 2 |
| `references/phase3-writing.md` | Phase 3 |
| `references/phase4-citations.md` | Phase 4 |
| `references/phase5-latex.md` | Phase 5 (FULL only) |
| `references/phase6-factcheck.md` | Phase 6 |
| `references/phase7-review.md` | Phase 7 |
| `references/phase8-final.md` | Phase 8 |
| `references/phaseR-digest.md` | Phase R (RESEARCH-ONLY) |
| `references/gate-protocol.md` | First gate encountered |
| `references/compaction.md` | Compaction fires or context discussion |
| `references/quality.md` | Quality decisions needed |
| `references/post-review.md` | After GATE 4 (Post-Review Revision) |

## Integrations

The orchestrator integrates with K-Dense-AI scientific-agent-skills for enhanced capabilities. All are optional — the pipeline runs without them, but quality degrades gracefully.

**Install**: `npx skills add K-Dense-AI/scientific-agent-skills -y`

| Skill | Used In | Role | Fallback if Missing |
|-------|---------|------|---------------------|
| paper-lookup | Phase 2 (4th parallel agent) | 10-database unified literature search | Use MCP paper-search only |
| scientific-critical-thinking | Phase 6 (Step 6.6) | GRADE evidence grading, bias detection, logical fallacy audit | Skip; fact-check alone |
| peer-review (K-Dense) | Phase 7 (4th reviewer) | CONSORT/STROBE/PRISMA + statistical rigor + ethics | Required (covers dimensions our 3 reviewers don't) |
| scholar-evaluation | Phase 7.5 | 8-dimension ScholarEval quantitative scoring | Skip; qualitative reviews only |


**Requirements**: Python 3.11+, `uv` package manager. All integrated skills are instruction-only (no paid APIs, no code execution required). API keys (NCBI, CORE) are optional and free — not required for basic operation.

**Do NOT pre-read future phase files. Only read the file for the phase you are starting.**
