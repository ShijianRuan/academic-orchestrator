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
  version: "6.0.0"
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

Supporting protocols (compaction recovery, quality heuristics, post-review revision, gate enforcement) are also in `references/` — load them when the relevant situation arises, not upfront.

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
  Phase 2  RESEARCH → Parallel multi-source (Agent x 3, bg) → Merge → Citation chaining
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
| 1 | Agent directly + AskUserQuestion | Clarify scope |
| 2 | Agent (bg, parallel) x 3 + S2 MCP | Full parallel search + citation chaining |
| 3.1 | MCP + WebFetch | Round 1 structure reads |
| 3.2 | Agent (bg) with full writing skill instructions | Structural draft |
| 3.3 | Agent (bg, parallel) x 2 | Round 2 detail reads (MANDATORY) |
| 3.4 | Agent (bg, parallel) x 3 | Prose + Citation + Data audit |
| 3.5 | Main session | Merge refinements |
| 3.6 | gh + WebFetch (opt) | Code repository audit |
| 3.7 | WebFetch (opt) | Figure/table extraction |
| 4 | Agent (bg) with full citation-management instructions | BibTeX + retraction check |
| 5 | Skill (latex-paper-en) | LaTeX conversion (FULL only) |
| 6 | Skill (fact-check) | Verification (KEEP in main session) |
| 7 | Agent (bg, parallel) x 3 | 3 peer reviewers |
| 8 | Agent (bg) + Skill | Language polish + final output |

---

## Context Management

### File Disposal Rules (MANDATORY)

To prevent context exhaustion, dispose of these files from working memory at the specified checkpoints:

| Checkpoint | Dispose from Memory | Recovery Method |
|-----------|-------------------|-----------------|
| After Phase 2.3 merge | phase2-deep-research.md, phase2-academic-researcher.md, phase2-medical-imaging.md | Read from disk if needed |
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
| 1 | 1, 2, 3 | 25-45K (was 60-85K before v6.0.0 optimizations) |
| 2 | 4, [5] | 5-15K |
| 3 | 6, 7, 8 | 20-40K |

---

## Gates (Quick Reference)

5 gates. Each gate MUST use AskUserQuestion and wait for explicit confirmation.
Gate details: Read `references/gate-protocol.md` at the first gate you encounter.

| Gate | When | Check |
|------|------|-------|
| GATE 1 | Phase 1 → 2 | Research plan confirmed |
| GATE 2 | Phase 3 → Session 2 | Draft + Round 2 assessment reviewed |
| GATE 3 | Phase 6 → 7 | Fact-check results reviewed |
| GATE 4 | Phase 7 → revision | Peer review consensus + revision plan |
| GATE 5 | Phase 8 → delivery | Final sign-off |

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

**Do NOT pre-read future phase files. Only read the file for the phase you are starting.**
