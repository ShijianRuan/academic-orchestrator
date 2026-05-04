# Phase 8: Final Output

## Input Convention
- Reads the latest draft (post-revision if Phase 7R was executed)
- Reads `references.bib`
- Output: final package in `research-output/`, `VERIFICATION_STATUS.md`

---

## Phase 8: Final Output

### Step 8.1: Final Validation

Invoke `citation-management` skill to run final validation on `references.bib`.

### Step 8.2: Language Polish

Launch a **subagent** with the draft and the Elements of Style guide for final language polish. This follows the writing-clearly-and-concisely skill's own recommended pattern for tight-context situations:

1. Launch Agent (bg): `subagent_type: "general-purpose"`, description: "Language polish"
2. Prompt: "Read the draft at research-output/phase3-draft-v1.md. Then read ~/.claude/skills/writing-clearly-and-concisely/elements-of-style.md. PRE-PROCESSING: First, REMOVE all HTML comment markers (<!-- PHASE_X_COMPLETE -->, <!-- UNIT_N_OF_M_COMPLETE -->) — these are pipeline artifacts, not manuscript content. Then apply ALL Strunk rules: active voice, positive form, definite specific concrete language, omit needless words, keep related words together, place emphatic words at end. Do NOT change facts, citations, structure, or argument. Write the polished version to research-output/phase3-draft.md and a completion report to research-output/phase8-style-check.md confirming marker removal + rule application."
3. This is a purely stylistic pass — it improves clarity, concision, and professionalism WITHOUT changing factual content or argument structure.
4. If LaTeX output, invoke `latex-paper-en` skill after language polish for final formatting consistency check.

### Step 8.3: Final LaTeX Pass (FULL strategy only)

Invoke `latex-paper-en` skill for final formatting, consistency, and compilation check.

### Step 8.4: Generate Final Package

Produce these deliverables in the project directory:

```
research-output/
  phase1-plan.md           — Research plan
  phase2-deep-research.md  — Web research notes
  phase2-academic-researcher.md — Academic research notes
  phase2-medical-imaging.md     — (if MEDICAL) Domain notes
  phase2-merged.md         — Cross-validated synthesis
  phase3-draft.md          — Initial draft
  phase4-citation-report.md — Citation issues log
  phase6-factcheck.md      — Verification report
  phase6-corrections.md    — Changes made
  phase7-peerreview.md     — Peer review report

manuscript.tex             — Final LaTeX manuscript
references.bib             — Validated BibTeX database
VERIFICATION_STATUS.md     — Overall confidence + caveats
```

### Step 8.5: Final Summary

Report to user:
- Word count, source count, reference count
- Fact-check confidence level
- Peer review recommendation
- Any remaining unverified claims or caveats
- How to compile (pdflatex / xelatex / lualatex command)

### GATE 5: Final delivery.

Ask: "All deliverables are ready in `research-output/`. Would you like me to: (a) walk through the verification report, (b) list any remaining unverified claims, or (c) deliver as final?" This is the last checkpoint — the user signs off on the complete package.

**Before GATE 5, run**: `bash scripts/validate.sh GATE_5 research-output/`. If exit ≠ 0 → fix all FAIL items → re-run → repeat until clean. Only then present the gate to the user.

---

