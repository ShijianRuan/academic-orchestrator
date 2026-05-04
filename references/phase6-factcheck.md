# Phase 6: Fact-Check + Adversarial Verification

## Input Convention
- Reads `phase3-draft.md` (primary verification target)
- Reads `references.bib` (for citation lookups — on demand, not in memory)
- Does NOT require `phase2-merged.md` (disposed after Phase 3). If a claim needs source tracing, read it from disk on demand.
- Output: `phase6-factcheck.md`, `phase6-corrections.md`

## Important
This phase uses **Skill tool (fact-check)**, not Agent tool.
Fact-checking is subjective-judgment-intensive and requires the full context chain from Phases 1-5. The fact-check skill is loaded in the main session.

---

## Phase 6: Fact-Check (Independent Pass)

**Critical constraint**: This MUST be a separate pass after writing is complete. Do NOT combine with Phase 3 or Phase 5.

Invoke `fact-check` skill via the Skill tool.

The fact-check skill provides a four-phase verification methodology. You MUST execute all four phases — this is not optional. The skill's methodology is the standard, not a suggestion.

**Phase 1 — Claim Extraction (output: complete claim list in phase6-factcheck.md)**:
- Read the draft paragraph by paragraph
- Extract EVERY verifiable statement: numbers, attributions, comparisons, factual assertions
- Write the full claim list to phase6-factcheck.md before proceeding to Phase 2
- Do NOT skip claims that "look right" — extract first, verify second

**Phase 2 — Claim Categorization (output: category per claim)**:
- Tag each claim as: Verifiable-Hard (numbers, dates) / Verifiable-Soft (general facts) / Attribution (who said what) / Inference (conclusion from evidence)
- This determines verification strategy: Hard → exact match required. Soft → substantial support. Attribution → verify source and statement.

**Phase 3 — Per-Claim Source Verification (output: finding per claim)**:
- For EACH claim, check against the cited source:
  - CONFIRMED: source explicitly supports the claim
  - PARTIALLY SUPPORTED: source supports part but not all → narrow the claim
  - NOT FOUND: no source located → mark unverified
  - CONTRADICTED: source says opposite → remove or correct immediately
- Do not batch-verify. Each claim must have an individual finding.

**Phase 4 — Confidence Assignment (output: overall confidence)**:
- HIGH: all key claims verified, no contradictions
- MEDIUM: most claims verified, some unverified but plausible
- LOW: significant claims unverified, corrections needed

Output to `research-output/phase6-factcheck.md`:
- Per-claim verification log (claim → category → source checked → finding → confidence)
- Overall confidence level
- List of corrections applied

### Post-Verification Actions
- CONFIRMED claims → keep, add source citation
- PARTIALLY SUPPORTED → narrow the claim to match the source
- NOT FOUND → mark as unverified or remove
- CONTRADICTED → remove or correct immediately

Apply all corrections to the draft (`phase3-draft.md`). Record changes in `research-output/phase6-corrections.md`.

### Adversarial Verification (Counter-Evidence Search)

Fact-check verifies "is this claim supported by its cited source?" — but does NOT ask "is there evidence AGAINST this claim?" Adversarial verification closes this gap.

**Process:**
1. Take the top 3-5 HIGH-confidence claims from the fact-check report
2. For each claim, run a targeted search for counter-evidence: "[claim keywords] controversy criticism limitation rebuttal"
3. If counter-evidence is found → downgrade confidence to Medium, add caveat to the manuscript
4. If no counter-evidence → confidence confirmed as HIGH

**Output**: Append an "Adversarial Verification" section to `research-output/phase6-factcheck.md` with the results. This step takes ~5 minutes and catches the most dangerous type of error — consensus claims that the field has moved past.

### Step 6.4.5: Evidence Grade Audit (MANDATORY — mechanical check)

The fact-check pass must verify that the evidence grades [A/B/C/D] assigned in the draft's References section match actual publication venues. This was a blind spot: our test found arXiv preprints labeled [A] that should have been [C] per our own rubric. The fact-check entirely missed this.

**Process**:
1. Extract every reference with its evidence grade from the draft's References section
2. For each [A]-graded reference, verify the venue IS a peer-reviewed journal or top conference (NeurIPS, CVPR, MICCAI, Nature Methods, IEEE TMI, Medical Image Analysis, etc.)
3. For arXiv preprints: unless also published in a peer-reviewed venue → downgrade to [C]
4. For [B]-graded: verify it IS a workshop or lower-tier journal
5. Flag as **[GRADE-MISMATCH: [X] should be [Y] — arXiv preprint]** or similar

**Output**: Append an "Evidence Grade Audit" section to `phase6-factcheck.md` listing every mismatch found and the corrected grade. Apply corrections to the draft References section.

This is a mechanical check — it requires no semantic judgment, only cross-referencing venue names against a known list of top venues. It takes ~2 minutes and prevents the systematic grade inflation the test exposed.

### Known Blind Spots

Fact-check verifies "is this claim supported by its cited source?" — it does NOT verify:

| Blind Spot | Risk | Mitigation |
|-----------|------|------------|
| **Source correctness** | Claim cites a real paper that says X, but the correct/best source says Y | Peer review (Phase 7) — domain expert catches misattributed consensus |
| **Reasoning chain integrity** | Each claim individually verified, but A→B→C logic may still break | Peer review (Phase 7) — methodologist checks argument structure |
| **Data staleness** | 2020 SOTA cited as current in 2026 | Adversarial verification (Phase 6) searches for counter-evidence and newer results |
| **Negative findings omission** | Source found that supports claim, but stronger source contradicts it | Adversarial verification searches specifically for contradiction |
| **Evidence grade mislabeling** | arXiv preprints labeled [A], workshops labeled [A] | Mechanical grade audit (Step 6.4.5) — cross-references venue against rubric |

These blind spots are inherent to claim-level verification. They are addressed by
the multi-layered quality architecture (adversarial search + grade audit + 4-reviewer peer review),
not by the fact-check pass alone.

### Step 6.5: Apply Corrections to Draft (MANDATORY — before GATE 3)

Fact-check corrections MUST be applied BEFORE peer review. Reviewers should review the corrected draft, not a draft with known errors.

1. Read `phase6-factcheck.md` — extract every correction
2. Apply each correction to the draft (`phase3-draft-v1.md` or `phase3-draft.md`):
   - CONFIRMED → keep
   - PARTIALLY SUPPORTED → narrow the claim to match source
   - NOT FOUND → mark as `[UNVERIFIED]` in text
   - CONTRADICTED → remove or correct
3. Write `research-output/phase6-corrections-applied.md` containing:
   - Per-correction: original text → corrected text (diff format)
   - Section and paragraph where applied
   - Any corrections DECLINED (with reason)
4. This file is a **GATE 3 Layer 1 dependency** — its absence means corrections were found but never applied. GATE 3 CANNOT PASS without it.

### Step 6.6: Scientific Critical Thinking Audit (via Skill: scientific-critical-thinking)

After corrections are applied but BEFORE GATE 3, run an evidence-quality and bias audit:

Invoke `scientific-critical-thinking` skill to evaluate:
- **GRADE evidence grading**: Rate each key claim's supporting evidence quality
- **Bias detection**: Check for confirmation bias, selection bias, p-hacking, cherry-picking, HARKing
- **Logical fallacy identification**: Causation fallacies, overgeneralization, statistical fallacies
- **Claim-evidence mismatch**: Are causal claims supported by correlational evidence? Are confidence levels proportional to evidence strength?

Output to `research-output/phase6-critical-thinking.md`. Any HIGH-severity issues → fix before GATE 3.

### GATE 3: Present fact-check summary + adversarial verification to the user.

Show: overall confidence level, number of claims confirmed/unverified/contradicted, and corrections applied (with count from phase6-corrections-applied.md). If `phase6-corrections-applied.md` does not exist → return to Step 6.5. Ask: "Shall I proceed to peer review with these corrections, or would you like to review the fact-check details first?" Do NOT proceed to Phase 7 until the user confirms.

**Before GATE 3, run**: `bash scripts/validate.sh GATE_3 research-output/`. If exit ≠ 0 → fix all FAIL items → re-run → repeat until clean. Only then present the gate to the user.

---

