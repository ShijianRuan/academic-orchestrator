# Phase 7: Multi-Reviewer Peer Review

## Input Convention
- Reads `phase3-draft.md` (or `phase3-draft-v1.md`)
- Reads `phase6-factcheck.md` (fact-check results + known blind spots)
- Output: `phase7-reviewer-a.md`, `phase7-reviewer-b.md`, `phase7-reviewer-c.md`, `phase7-peerreview-merged.md`
- Post-review revision: see `references/post-review.md`

---

## Phase 7: Multi-Reviewer Peer Review

Three independent reviewers evaluate the manuscript in parallel — mirroring real academic peer review where 2-3 reviewers catch different issues and consensus strengthens signals. Same pattern as Phase 2: launch agents in ONE message, they run concurrently, then merge.

### Step 7.1: Launch Reviewers in Parallel

Launch 3 Agent tasks IN A SINGLE MESSAGE with `run_in_background: true`. Each gets a distinct reviewer persona:

```
Agent tool call 1 (run_in_background: true):
  subagent_type: "general-purpose"
  description: "Reviewer A — Methodologist"
  prompt: |
    You are Reviewer A — a PhD-level methodological specialist. Read the manuscript below and evaluate it using the peer-review framework: dimensional scoring (1-5) on Novelty, Rigor, Impact, Clarity. Your PRIMARY focus is METHODOLOGICAL SOUNDNESS:
    - Are the methods correctly described and appropriate?
    - Are statistical claims properly supported?
    - Are there gaps in experimental validation?
    - Are the conclusions warranted by the evidence presented?
    Return your review AS TEXT. Structure:
    ## Reviewer A — Methodologist
    **Recommendation**: [Accept/Minor/Major/Reject]
    **Scores**: Novelty:[S] Rigor:[S] Impact:[S] Clarity:[S]
    **Major Issues**: [numbered list with specific evidence from the text]
    **Minor Issues**: [numbered list]
    Do NOT try to write files. Return text inline.
    
    Manuscript:
    Draft:
    [If draft ≤8,000 words: paste full content below]
    [If draft >8,000 words: Read the file at research-output/phase3-draft.md]
    [INSERT DRAFT OR FILE REFERENCE HERE]
    Fact-check report: [paste phase6-factcheck.md summary]

Agent tool call 2 (run_in_background: true):
  subagent_type: "general-purpose"
  description: "Reviewer B — Domain Expert"
  prompt: |
    You are Reviewer B — a senior domain expert in the paper's specific field. Read the manuscript below. Your PRIMARY focus is DOMAIN ACCURACY AND COVERAGE:
    - Does the paper accurately represent the state of the field?
    - Are there missing seminal works or important recent papers?
    - Are the claims consistent with domain knowledge?
    - Is the clinical/practical framing accurate and useful?
    Return your review AS TEXT. Structure:
    ## Reviewer B — Domain Expert
    **Recommendation**: [Accept/Minor/Major/Reject]
    **Scores**: Novelty:[S] Rigor:[S] Impact:[S] Clarity:[S]
    **Major Issues**: [numbered list]
    **Missing Literature**: [papers the manuscript should cite but doesn't]
    **Minor Issues**: [numbered list]
    Do NOT try to write files. Return text inline.
    
    Manuscript:
    Draft:
    [If draft ≤8,000 words: paste full content below]
    [If draft >8,000 words: Read the file at research-output/phase3-draft.md]
    [INSERT DRAFT OR FILE REFERENCE HERE]
    Fact-check report: [paste phase6-factcheck.md summary]

Agent tool call 3 (run_in_background: true):
  subagent_type: "general-purpose"
  description: "Reviewer C — Generalist / Editor"
  prompt: |
    You are Reviewer C — an experienced journal editor with a generalist perspective. Read the manuscript below. Your PRIMARY focus is CLARITY, STRUCTURE, AND ACCESSIBILITY:
    - Is the argument flow logical and easy to follow?
    - Is the writing clear and well-structured?
    - Would a non-specialist reader understand the contribution?
    - Are figures/tables well-designed and informative?
    - Is the abstract accurate and compelling?
    Return your review AS TEXT. Structure:
    ## Reviewer C — Generalist / Editor
    **Recommendation**: [Accept/Minor/Major/Reject]
    **Scores**: Novelty:[S] Rigor:[S] Impact:[S] Clarity:[S]
    **Major Issues**: [numbered list]
    **Structural/Clarity Issues**: [specific examples from the text]
    **Minor Issues**: [numbered list]
    Do NOT try to write files. Return text inline.
    
    Manuscript:
    Draft:
    [If draft ≤8,000 words: paste full content below]
    [If draft >8,000 words: Read the file at research-output/phase3-draft.md]
    [INSERT DRAFT OR FILE REFERENCE HERE]
    Fact-check report: [paste phase6-factcheck.md summary]
```

### Step 7.2: Merge Reviews (from files, clear raw results)

When ALL 3 reviewers complete, for each reviewer:
1. Extract the full review from the completion notification
2. Write to its file immediately: `research-output/phase7-reviewer-a.md`, `phase7-reviewer-b.md`, `phase7-reviewer-c.md`
3. **After writing all 3 files: clear raw review text from working memory.** The files on disk are the authoritative record

Then read the 3 files from disk and produce the merged report `research-output/phase7-peerreview-merged.md`:

```markdown
# Peer Review — Consolidated Report

## Reviewer Recommendations
| Reviewer | Role | Recommendation | N | R | I | C |
|----------|------|------------------|---|---|---|---|
| A | Methodologist | [Verdict] | | | | |
| B | Domain Expert | [Verdict] | | | | |
| C | Generalist | [Verdict] | | | | |

## Consensus Issues (found by 2+ reviewers → MUST FIX)
1. [Issue] — Reviewers A, B

## Individual Issues (found by 1 reviewer → SHOULD FIX)
### From Reviewer A (Methodologist)
- [Issue]

### From Reviewer B (Domain Expert)
- [Issue]

### From Reviewer C (Generalist)
- [Issue]

## Missing Literature (from Reviewer B)
- [Paper title] — relevance: [why it should be cited]

## Final Recommendation
Weighted by reviewer role. If 2+ reviewers agree on the verdict → that verdict. If all 3 disagree → flag for user decision.
```

### GATE 4: Present merged review to the user.

Show: consensus recommendation, score matrix, consensus issues vs individual issues. Ask: "Accept all consensus fixes? Override any individual reviewer suggestions?" Apply user's decisions. If Major Revision from 2+ reviewers: offer to loop back to Phase 3. If Reject from 2+: flag with specific reasoning.

### Post-Review Revision Protocol

Post-review revision is NOT ad-hoc editing. It is a structured mini-pipeline that reuses existing Phase components. The exact path depends on what the reviewers found — this is a dispatch framework, not a rigid sequence.

#### Step 1: Create Revision Plan (always required)

Categorize every reviewer issue and write `research-output/phase7-revision-plan.md`:

| Category | Examples |
|----------|----------|
| **FACT** | Wrong numbers, incorrect attributions, data discrepancies |
| **CITATION** | Missing references, misattributed citations |
| **STRUCTURE** | Section reorganization, missing subsections, argument flow |
| **CONTENT** | Missing method descriptions, absent benchmark comparisons, thin analysis |
| **LANGUAGE** | Terminology errors, clarity issues, hedging overuse |
| **DATA** | Dataset errors, licensing gaps, benchmark inaccuracies |

#### Step 2: Execution Order (topological — dependencies enforced)

Fixes are NOT independent. Execute in this order; skip empty categories:

| Order | Category | Rationale |
|-------|----------|-----------|
| 1 | **STRUCTURE** | Section moves invalidate all position-based fix targets. Must go first. |
| 2 | **FACT** | Content additions may depend on correct numbers being in place. |
| 3 | **CONTENT** | Additions must land in stable sections with verified facts. |
| 4 | **CITATION** | All content must be in place before adding cross-references. |
| 5 | **DATA** | Dataset verification runs in parallel with CITATION (independent). |
| 6 | **LANGUAGE** | LAST — polishing before content is stable wastes effort. |

Each category maps to its reusable component (same as before):

| Category | Reusable Component | How |
|----------|-------------------|-----|
| STRUCTURE | Phase 3.1 (structure reads) | Revise field-structure → adjust outline |
| FACT | Phase 6 (fact-check) | Re-verify specific claims against sources |
| CONTENT | Phase 3.3 (Round 2 detail reads) | Deep-read targeted papers → add missing detail |
| CITATION | Phase 4 (citation-management) | Add/fix references in .bib and draft |
| DATA | Phase 3.4 Agent C (data audit) | Re-audit specific datasets |
| LANGUAGE | Phase 3.4 Agent A (prose) or Phase 8.2 (style) | Language refinement pass |

#### Step 3: Apply Fixes with Traceability

- Each fix must reference the reviewer issue number it addresses
- **FACT fixes**: run a spot fact-check on ONLY the changed claims (not the full manuscript)
- **CONTENT additions**: deep-read the relevant papers BEFORE writing (use Step 3.3 pattern)
- **CITATION fixes**: add to both the draft inline citations AND references.bib

#### Step 4: Verification (proportional to scope)

| Fix Scope | Verification |
|-----------|-------------|
| FACT fixes ≥ 3 claims | Targeted fact-check on changed sections only |
| CITATION fixes ≥ 5 refs | Re-run citation audit on new refs only |
| STRUCTURE changes | Re-read revised sections for logical flow |
| CONTENT additions | Verify new numbers against deep-read extracts |

#### Step 4.5: Regression Check (MANDATORY, ~2K tokens)

After all fixes applied and verified, check that fixes did not introduce new problems:

1. **Adjacent paragraph check**: For EVERY modified paragraph, read 1 paragraph before and 1 after:
   - Does the transition still read naturally?
   - Are cross-references still correct? (e.g., "as discussed in Section 3.2" — did section numbers change?)
2. **New content check**: For EVERY new content addition:
   - Does it contradict any existing claim elsewhere in the manuscript?
   - Does it duplicate content already present?
3. **Compilation check** (LaTeX only): Run `pdflatex -interaction=nonstopmode` to catch syntax errors
4. Write results to `research-output/phase7-regression-check.md`:
   - [PASS] no issues / [FIXED] issue found and resolved / [KNOWN] minor, documented

#### Step 5: Revision Report + Mini-Gate

Write `research-output/phase7-revision-report.md`:
- Issue → Category → Action taken → Verification result → Regression check
- Mark any reviewer issues explicitly declined with reason

**Mini-gate (required before Phase 8)**: Use AskUserQuestion to present:
"Revision complete — [N] issues addressed, [M] verified, [D] declined (with reasons), regression check [PASS/FIXED]. Proceed to Phase 8, or loop back?"

#### Loop-Back Decision Matrix

Do NOT trigger loop-back by count alone. Ask: **do these errors share a root cause?**

| Scenario | Local Fix (targeted) | Systemic Loop-Back |
|----------|---------------------|-------------------|
| FACT fixes ≥5 | Independent number errors → spot-check each | Same data source/paper wrong throughout → Phase 6 full |
| STRUCTURE ≥3 sections | Adding subsections → edit in place | Argument logic needs reorganization → Phase 3.1 |
| CONTENT ≥3 sections | Supplementing details → deep-read + insert | Fundamental gaps in coverage → Phase 3 re-draft |

**Decision rule**: errors with a COMMON ROOT CAUSE → systemic → loop-back. Independent/unrelated errors → local fix → targeted verification.

#### Loop-Back Return Rules

If the user chooses loop-back at the mini-gate:

1. **Loop-back to Phase 3** → produces new draft → return to Phase 3 GATE 2
   → then re-run Phase 4 → Phase 6 → Phase 7
   → Phase 7 re-review: annotate reviewer prompts with "Focus on sections [X, Y, Z]. Other sections unchanged."
2. **Loop-back to Phase 6** → produces new fact-check → return to Phase 6 GATE 3
   → then re-run Phase 7 (reviewers see only changed claims)
3. **Loop-back to Phase 3.1** → produces new field-structure → return to Phase 3.2
   → then re-run Phase 3.3 → 3.4 → 3.5 → GATE 2 → Phase 4 → Phase 6 → Phase 7

**Hard limits**:
- Maximum loop-back passes: **2**. On the third attempt, inform user and recommend human intervention. Do NOT loop infinitely.
- Phase 7 re-review after loop-back is **scoped**: reviewers annotate their output with which sections they reviewed. Unchanged sections carry forward the previous review verdict.
- These are OFFERS to the user, not automatic — the user decides whether to loop back or proceed with targeted fixes.

---

