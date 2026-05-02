# Phase R: Research Digest Output (RESEARCH-ONLY)

## Input Convention
- Reads `phase2-merged.md` (cross-validated research synthesis)
- Output: `research-output/research-digest.md`

---

## Phase R: Research Digest Output (RESEARCH-ONLY strategy)

**Phase R replaces Phases 3-8 for RESEARCH-ONLY strategy.** The user wants a single, scannable research digest — not a paper.

### Step R.1: Choose Output Format

Read the user's research question and the merged findings. Choose ONE primary format that best answers their question. Do NOT default to tables — pick the format that communicates most effectively.

| Question Type | Best Format | Example |
|--------------|-------------|---------|
| "Compare A vs B" | Comparison table or side-by-side pros/cons | "对比 nnU-Net 和 SAM 在器官分割上的表现" |
| "What methods exist?" | Categorized list with strengths/weaknesses | "全身器官分割有哪些方法" |
| "What's the consensus?" | Agreement matrix or "What we know / What's contested / What's missing" | "领域共识是什么" |
| "How did we get here?" | Timeline or milestone list | "这个领域的发展历程" |
| "What should I do?" | Recommendations list with rationale and confidence | "我该用什么方法" |
| "What data is available?" | Dataset table | "有哪些公开数据集" |
| "What's the latest?" | Reverse-chronological highlights or trend summary | "最新进展" |
| "Mixed / broad topic" | Executive summary + key findings + whatever formats fit each subsection | "调研全身器官分割" |

### Step R.2: Generate the Digest

Generate `research-output/research-digest.md`. All content in ONE file. The skeleton adapts to the chosen format, but always includes:

```markdown
# Research Digest: [Topic]
*Date | Sources: [N] | Strategy: RESEARCH-ONLY | Confidence: [HIGH/MEDIUM/LOW]*

## What We Know *(required)*
[3-5 sentence executive summary. Answers the user's question directly — don't bury the lead.]

## [Body — format chosen in Step R.1] *(required)*
*This section's structure matches the question type. Examples:*
- Comparison table (methods/datasets/tools side-by-side)
- Categorized list (by approach, by evidence strength, by chronology)
- Agreement matrix (consensus vs contested vs unknown)
- Timeline (year, milestone, significance, source)
- Recommendations (action, rationale, confidence, caveats)
*Tables are ONE option among many. Use the format that communicates best.*

## What's Contested / What's Missing *(required)*
[3-5 gaps, contradictions, or open questions. Every research digest should tell the user what we DON'T know.]

## Cross-Validation Summary *(required)*
| Claim | deep-research | academic-researcher | [medical] | Strength |
|-------|--------------|--------------------|-----------|----------|
| [Claim] | ✅ | ✅ | ✅ | HIGH |
| [Claim] | ✅ | ❌ | — | Single |

## Annotated Sources *(required)*
| # | Title (Author, Year) | Type [A/B/C/D] | Found By | 1-Line Relevance |
|---|---------------------|----------------|----------|-----------------|

*Sources sorted by evidence level then recency. Full URLs/DOIs inline.*

## Raw Research Files *(required — for traceability)*
- `research-output/phase2-deep-research.md` — Full web perspective notes
- `research-output/phase2-academic-researcher.md` — Full academic perspective notes
- `research-output/phase2-medical-imaging.md` — Full medical imaging notes (if MEDICAL strategy)
- `research-output/phase2-merged.md` — Cross-validated synthesis with evidence levels

*If any claim in this digest needs verification or more detail, the raw files above contain the original agent output.*
```

### Design Principles

- **Format follows question**: don't force methods into a table or trends into a list. Pick the format that answers the user's actual question
- **Lead with the answer**: executive summary states the conclusion first, not the process
- **What we DON'T know is as important as what we do**: every digest must include gaps and contested claims
- **Evidence levels everywhere**: every claim/source tagged [A/B/C/D]. Every finding tagged with consensus strength
- **Single file, scannable in 60 seconds**: no separate files, no redundant content across sections
- **Back-linked to raw research**: the digest footer must include a "Raw Research Files" section linking to `phase2-deep-research.md`, `phase2-academic-researcher.md`, etc. for traceability

### Step R.3: Language Polish (Prose Sections Only)

After generating the digest, invoke `writing-clearly-and-concisely` skill (Elements of Style) for a quick language pass on the prose sections (Executive Summary, Key Findings, Gaps). This is lightweight (~2K tokens) and catches passive voice, wordiness, and unclear phrasing. Do NOT apply to tables or source list — those are structural, not prose.

### Step R.4: Lightweight Self-Check (MANDATORY)

Before delivering the digest, verify the top-5 most consequential claims:

1. Extract the 5 claims with the highest decision impact (hard numbers, key attributions, comparative claims)
2. For each claim, check against `research-output/phase2-merged.md`:
   - **Match**: claim is supported by at least one agent's findings → keep
   - **No match**: claim cannot be verified against Phase 2 → mark with [UNVERIFIED] in the digest
3. Add a "Verification Note" footer to the digest:
   ```
   **Verification Note**: N/5 key claims verified against Phase 2 multi-source research.
   [If any UNVERIFIED]: The following claims could not be verified and should be treated 
   as uncertain: [list]. Full fact-check (Phase 6) recommended if this digest informs 
   publication or decisions.
   ```

This is NOT a full fact-check — it takes ~2 minutes and catches the most dangerous
errors without significant context cost. It does not replace Phase 6 for publication-grade output.

---

