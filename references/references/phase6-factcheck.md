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

Provide `manuscript.tex` (or `research-output/phase3-draft.md` if LaTeX not yet generated).

Output to `research-output/phase6-factcheck.md`:
- Every verifiable claim extracted and categorized (Verifiable-Hard / Verifiable-Soft / Attribution / Inference)
- Each claim checked against its source
- Confidence: Confirmed / Partially Supported / Not Found / Contradicted
- Overall reliability: High / Medium / Low / Unreliable

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

### Known Blind Spots

Fact-check verifies "is this claim supported by its cited source?" — it does NOT verify:

| Blind Spot | Risk | Mitigation |
|-----------|------|------------|
| **Source correctness** | Claim cites a real paper that says X, but the correct/best source says Y | Peer review (Phase 7) — domain expert catches misattributed consensus |
| **Reasoning chain integrity** | Each claim individually verified, but A→B→C logic may still break | Peer review (Phase 7) — methodologist checks argument structure |
| **Data staleness** | 2020 SOTA cited as current in 2026 | Adversarial verification (Phase 6) searches for counter-evidence and newer results |
| **Negative findings omission** | Source found that supports claim, but stronger source contradicts it | Adversarial verification searches specifically for contradiction |

These blind spots are inherent to claim-level verification. They are addressed by
the multi-layered quality architecture (adversarial search + 3-reviewer peer review),
not by the fact-check pass alone.

### GATE 3: Present fact-check summary + adversarial verification to the user.

Show: overall confidence level, number of claims confirmed/unverified/contradicted, and any corrections applied. Ask: "Shall I proceed to peer review with these corrections, or would you like to review the fact-check details first?" Do NOT proceed to Phase 7 until the user confirms.

---

