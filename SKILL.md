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
  version: "5.3.0"
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

**Critical design decision**: The full 8-phase pipeline exceeds a single Claude Code session's context budget. Each skill invocation alone costs 5-15K tokens to load, agent results can reach 30K tokens each, and the draft + fact-check both need the full manuscript in context. The pipeline is therefore split across **3 sessions** bridged by files on disk, regardless of output format. Each session starts clean and loads only what it needs from previous outputs.

## Context Budget (Measured from Test Run)

| Session | Phases | Measured Token Range | Composition |
|---------|--------|---------------------|-------------|
| 1 | 1, 2, 2.4, 3 | 60-85K | Orchestrator (13K) + 3 search agents (30-50K) + writing skill (8K) + academic-writing (3K) + 2 deep-read agents* (0K main session, agents run bg) + enriched draft (6K) + discussion |
| 2 | 4, [+5 if LaTeX] | 15-35K | citation-management (8K) + bib validation + retraction check + [latex-paper-en (8K) + .tex] |
| 3 | 6, 7, 8 | 40-65K | fact-check (11K) + adversarial + manuscript (5K) + 3 reviewers parallel + elements-of-style (2K) |

*\*Phase 3.1b deep-read agents run in background with independent contexts. Their skill instructions are inline in the prompt, not loaded into the main session. Cost to main session: only the agent launch messages (~2K) + the enriched draft diff (+1-2K over v1). Net Session 1 increase: ~3K.*

**Rules to stay within budget:**
- After each session: immediately run `/compact` to summarize before the next
- Never load a skill's SKILL.md unless actually invoking it in that session
- **Agent result disposal**: After writing agent results to files (Phase 2.2 and Phase 3.1b), do NOT keep raw agent output in working memory. Read only the merged/enriched files for subsequent phases
- Session 3: fact-check the manuscript section by section, don't load all at once
- **Skill-as-Agent pattern**: for tasks that would load a large skill (analyzing-research-papers, peer-review), use Agent tool with inline instructions instead of Skill tool. The skill's methodology goes into the agent prompt — the main session never loads the skill file
- Skill invocation costs (loaded in main session): orchestrator (13K), literature-review (4K), medical-imaging-review (8K), academic-writing (3K), citation-management (8K), fact-check (11K), latex-paper-en (8K), elements-of-style (2K)
- Skills NOT loaded in main session (used via Agent tool): analyzing-research-papers (4K would-be), peer-review (3K would-be)
- **MCP servers added to ~/.claude.json only take effect after restarting Claude Code.** If agents report a new MCP tool is unavailable, the user needs to restart. Agent prompts include PRIMARY/FALLBACK tool instructions so search quality degrades gracefully when MCP tools are not yet loaded

## Architecture

Two paths diverge at Phase 1. RESEARCH-ONLY is single-session, lightweight. Full pipeline is 3-session, comprehensive.

### RESEARCH-ONLY Path (Single Session — ~35-45K tokens)

```
RESEARCH-ONLY (single session)
  Phase 1  SCOPE    → Clarify + route to RESEARCH-ONLY
  GATE 1: Confirm research plan
  Phase 2  RESEARCH → Parallel multi-source (Agent × 3, bg)
                      → Write to files → Clear → Merge
                      → Citation chaining (S2 MCP)
  Phase R  OUTPUT   → Generate directly (no external skill)
                      → Single file: research-digest.md
                      → Topic-adaptive tables + key findings + sources
  GATE R: Review digest → refine or deliver
  Output: research-output/research-digest.md
```

### Full Pipeline (3 Sessions)

```
SESSION 1 (research + draft) — ~55-80K tokens
  Phase 1  SCOPE    → Clarify + route
  GATE 1: Confirm research plan
  Phase 2  RESEARCH → Parallel multi-source (Agent × 3, bg)
                      → Write to files → Clear from memory → Merge
  Phase 3  DRAFT    → Academic writing
  GATE 2: Review draft
  Output: research-output/*.md
  END: /compact

SESSION 2 (citations + [format]) — ~15-35K tokens
  Load from files: phase3-draft.md, phase2-merged.md
  Phase 4  CITATIONS → .bib construction + DOI validation
  Phase 5  FORMAT    → [FULL: LaTeX conversion + diagnostics]
                       [Markdown-only: skipped — proceed to /compact]
  Output: manuscript.tex + references.bib, OR validated draft.md
  END: /compact

SESSION 3 (verify + review + final) — ~40-65K tokens
  Load from files: manuscript.tex (or phase3-draft.md), references.bib
  Phase 6  VERIFY    → Fact-check + adversarial verification
  GATE 3: Review verification results
  Phase 7  REVIEW    → 3 parallel peer reviewers → merge consensus
  GATE 4: Review consensus → decide on revisions
  Phase 8  FINAL     → Language polish + final output
  GATE 5: Final sign-off
  Output: Corrected manuscript, VERIFICATION_STATUS.md
```

## Skill Dispatch Matrix

### RESEARCH-ONLY Path (single session)
| Phase | Skill to Invoke | Tool | Notes |
|-------|----------------|------|-------|
| 1 | (Agent directly) + literature-review | AskUserQuestion | Clarify scope; adopt PRISMA/PICO framework |
| 2 | deep-research, academic-researcher, [+ medical-imaging-review] | Agent (bg, parallel) + S2 MCP | Full parallel search + citation chaining |
| R | (Agent directly) | Write | Structured tables + key findings + annotated sources (templates in Phase R spec) |

### Full Pipeline (3 sessions)
| Phase | Skill to Invoke | Tool | Notes |
|-------|----------------|------|-------|
| 1 | (Agent directly) + literature-review | AskUserQuestion | Clarify scope; adopt PRISMA/PICO framework |
| 2 | deep-research, academic-researcher, [+ medical-imaging-review] | Agent (bg, parallel) + S2 MCP | Full parallel search + citation chaining |
| 3 | 3.1: domain skill → 3.1b: analyzing-research-papers + Paper Search MCP + S2 MCP (deep-read ~30% sources) → 3.2: ∥ prose ∥ citations ∥ data licensing | Skill (3.1 + 3.1b) + MCP tools + Agent bg parallel (3.2) | Summaries → skill-based deep-read → parallel refine → merge |
| 4 | citation-management | Skill + WebFetch | .bib + retraction check + source quality annotation |
| 5 | latex-paper-en | Skill | Convert to .tex (FULL only) |
| 6 | fact-check | Skill | Verification + adversarial counter-evidence |
| 7 | peer-review (×3 parallel personas) | Agent (bg, parallel) | Methodologist + Domain Expert + Generalist |
| 8 | elements-of-style + citation-management + [latex-paper-en] | Skill | Language polish → citation validation → [LaTeX] |

---

## Phase 1: Scope & Route

### Step 1.1: Extract Requirements

Ask the user (use AskUserQuestion):
- "What is the topic and research question?"
- "What type of output?" — **Research digest** (tables + summaries, no paper) / Survey paper / Systematic review / Research proposal / Course paper
- "Target venue?" (if paper) — Conference / Journal / arXiv preprint / Course submission
- "Depth level?" — Quick overview / Standard review / Exhaustive systematic review
- "Any specific sources, papers, or angles to include/exclude?"

**If the user selects "Research digest"**: route to RESEARCH-ONLY strategy. This is a single-session, lightweight path that produces structured tables, annotated source lists, and a key-findings summary — no draft writing, no LaTeX, no peer review.

### Step 1.2: Domain Routing

```
Output type is "Research digest"?
  ├─ YES → Strategy: RESEARCH-ONLY
  │         Phase 2: deep-research + academic-researcher [+ medical-imaging-review]
  │         Phase R: research-synthesis skill → tables + summary + sources
  │         Single session, ~35-45K tokens
  │
  └─ NO → Topic is medical imaging AI (CT, MRI, X-ray, ultrasound, pathology)?
            ├─ YES → Strategy: MEDICAL
            │         Phase 2: deep-research + academic-researcher + medical-imaging-review
            │         Phase 3: medical-imaging-review (primary writer)
            │         Full 8-phase pipeline (3 sessions)
            │
            └─ NO → Is the topic academic/scholarly?
                      ├─ YES → Strategy: ACADEMIC
                      │         Phase 2: deep-research + academic-researcher
                      │         Phase 3: academic-researcher (primary writer)
                      │         Full 8-phase pipeline (3 sessions)
                      │
                      └─ NO → Strategy: GENERAL
                                Phase 2: deep-research only
                                Phase 3: academic-researcher
                                Full 8-phase pipeline (3 sessions)
```

### Step 1.3: Output the Research Plan

Write `research-output/phase1-plan.md`:
```markdown
# Research Plan: [Topic]
- **Strategy**: [MEDICAL/ACADEMIC/GENERAL]
- **Research questions**: [3-5 sub-questions]
- **Skills to invoke**: [list]
- **Output type**: [survey/systematic/proposal/paper]
```

### GATE 1: Present the plan to the user. Do NOT proceed to Phase 2 until the user confirms.

---

## Phase 2: Multi-Source Parallel Research

### Why Parallel (Not Sequential)

Each skill uses a disjoint source pool — they search different corners of the internet:
- `deep-research`: Firecrawl + Exa → general web, news, industry reports, blogs
- `academic-researcher`: Scholarly sources → peer-reviewed papers, structured analysis, citations
- `medical-imaging-review`: arXiv + PubMed + Zotero → domain-specific literature (MEDICAL only)

Running them sequentially is not just slower — it introduces bias. If deep-research runs first and finds X, academic-researcher may anchor on X and miss Y. Running them blind to each other, then cross-validating, catches more and overweights less.

**Cost-benefit**: 2-3 parallel agents instead of 1, but wall-clock time is ~the slowest single agent (60-90s), not the sum. Coverage gain is substantial — our test showed Agent 1 found physics-inspired attention mechanisms and frequency-domain approaches that Agent 2 missed, while Agent 2 found a specific ICLR paper and implementation details that Agent 1 missed. Only overlap: sparse attention / Focus trend. Combined coverage was ~3x either alone.

### Step 2.1: Launch Agents in a Single Message

**Critical**: Launch ALL agents by putting multiple Agent tool calls in ONE message. This is what makes them truly concurrent — each gets its own context window and runs independently. Use `run_in_background: true` so the main session is not blocked.

For each sub-question from Phase 1, launch:

```
Message to user: "Launching N parallel research agents for: [sub-question]..."

Agent tool call 1 (run_in_background: true):
  subagent_type: "general-purpose"
  description: "deep-research: [sub-question]"
  prompt: |
    You are doing multi-source web research. Search for: "[sub-question]"
    - Use WebSearch and/or firecrawl_search for broad coverage
    - Focus on: latest developments, news, industry reports, blog posts, non-academic sources
    - Find 5-10 key sources
    - Return your findings AS TEXT in your response. Structure them as:
      ## [Sub-question] — Web Perspective
      ### Key Findings
      1. [Finding] — Source: [title](url)
      2. ...
      ### Sources
      [numbered list with URLs]
    - Do NOT try to write files. Just return the text in your response.

Agent tool call 2 (run_in_background: true):
  subagent_type: "general-purpose"
  description: "academic-researcher: [sub-question]"
  prompt: |
    You are doing academic literature research. Search for: "[sub-question]"
    - REQUIRED: First call mcp__paper-search__search_arxiv(query="[sub-question]", maxResults=10) AND mcp__paper-search__search_pubmed(query="[sub-question]", max_results=10). EFFICIENCY: Issue ALL independent MCP calls in ONE message (batch them) to cut wall-clock time by 3-4x. CRITICAL: Pass a real keyword query — empty query returns daily-new-papers, not matches.
    - For bio/medical topics, also call mcp__paper-search__search_biorxiv + mcp__paper-search__search_medrxiv with the same query
    - Only if ALL MCP calls fail or return empty: fall back to WebSearch + firecrawl_search + exa
    - Focus on: peer-reviewed papers, methodology, experimental results, citations
    - Find 5-10 key papers
    - Return your findings AS TEXT in your response. Structure them as:
      ## [Sub-question] — Academic Perspective
      ### Key Papers
      1. [Paper title] ([Year]) — [1-line finding]. DOI/URL: [link]
      2. ...
      ### Methodological Themes
      [patterns across papers]
      ### Research Gaps
      [what's missing]
    - REPORT which tools you used: "[MCP: USED arxiv+pubmed]" or "[FALLBACK: reason]". Do NOT try to write files.

Agent tool call 3 (run_in_background: true) — MEDICAL strategy ONLY:
  subagent_type: "general-purpose"
  description: "medical-imaging: [sub-question]"
  prompt: |
    You are doing medical imaging literature research. Search for: "[sub-question]"
    - REQUIRED: First call mcp__paper-search__search_pubmed(query="[sub-question]", max_results=10) AND mcp__paper-search__search_medrxiv(query="[sub-question]", max_results=10) AND mcp__paper-search__search_biorxiv(query="[sub-question]", max_results=10). EFFICIENCY: Issue ALL independent MCP calls in ONE message (batch them) to cut wall-clock time by 3-4x. CRITICAL: Pass a real keyword query to each — empty query returns noise.
    - Only if ALL three MCP calls fail or return empty: fall back to firecrawl_search + WebSearch + exa
    - Focus on: clinical validation, Dice/HD95 metrics, public datasets used
    - Find 5-10 key papers
    - Return your findings AS TEXT in your response. Structure them as:
      ## [Sub-question] — Medical Imaging Perspective
      ### Key Papers
      1. [Paper title] ([Year]) — Method: [method], Dice: [score], Dataset: [dataset]. URL: [link]
      ...
    - REPORT which tools you used: "[MCP: USED pubmed+medrxiv+biorxiv]" or "[FALLBACK: reason]". Do NOT try to write files.
```

### Step 2.2: Collect Results, Write to Disk, Clear from Memory

When ALL agents complete, for each agent:
1. Extract the full findings from the completion notification text
2. Write to its file immediately — do NOT truncate or summarize: `research-output/phase2-deep-research.md`, `research-output/phase2-academic-researcher.md`, `research-output/phase2-medical-imaging.md` (if MEDICAL)
3. **After writing**: clear the raw agent output from working memory. The files on disk are the authoritative record

**Why the main session writes files, not agents**: Background agents may lack Write/Bash permissions. Main session persists them. 

**Why dispose of raw output**: Three agent results can total 30-50K tokens. Keeping them in working memory alongside the orchestrator, writing skill, and draft would exhaust the context budget before Phase 3 even begins. The files are on disk — subsequent phases read only the merged synthesis.

### Step 2.3: Merge & Cross-Validate (from files only)

Read phase2-deep-research.md, phase2-academic-researcher.md, and phase2-medical-imaging.md from disk. Do NOT use the raw agent completion text still in conversation memory — read the files. Then produce `research-output/phase2-merged.md`:

```markdown
# Merged Research Notes: [Topic]

## Agreements (found by 2+ skills → HIGH confidence)
- [Claim] — Sources: [d-r ref], [a-r ref]

## Unique Findings (found by 1 skill only)
### From deep-research
- [Finding] — Source: [ref]

### From academic-researcher
- [Finding] — Source: [ref]

## Contradictions (flagged for investigation)
- [Skill A says X] vs [Skill B says Y] — Resolution: [which is more credible and why]

## Source Inventory
| # | Title | Type | Source Skill | URL/DOI |
|---|-------|------|-------------|---------|
```

### Step 2.4: Citation Chaining (Discovery Beyond Keywords)

**Goal**: Keyword search misses papers that don't use the same terms. Citation chaining finds them through the citation graph.

1. From the merged source inventory, identify the **top-5 most impactful papers** (highest citation counts, seminal works, recent highly-cited surveys)
2. Use the `semantic-scholar` MCP tools (`mcp__semantic-scholar__papers-search-basic...`) to:
   - **Forward search**: Find papers that cite these top-5 papers → discover latest developments building on seminal work
   - **Backward search**: Extract the reference lists of these top-5 papers → find foundational works that keyword search may have missed
3. For any newly discovered papers that are highly relevant, add them to the source inventory in `phase2-merged.md`
4. Append a "Citation Graph Discoveries" section to the merged file listing 3-5 newly found papers

**Why this matters**: Our test run found 26 sources via keyword search alone. Citation chaining on nnU-Net and TotalSegmentator would discover papers that build on these methods but use different terminology — filling a known gap in keyword-only discovery.

### Quality Rules for Phase 2
- Every claim must have a source attached
- Contradictions must be explicitly flagged, not silently dropped
- If only one skill found a claim, mark it as "single-source — lower confidence"
- **Evidence strength ladder**: Annotate each source in the merged inventory with its evidence level:
  - `[A]` Peer-reviewed journal article / top conference (NeurIPS, CVPR, MICCAI)
  - `[B]` Peer-reviewed conference workshop / lower-tier journal
  - `[C]` Preprint (arXiv, bioRxiv, etc.) — not yet peer-reviewed
  - `[D]` Grey literature (industry report, blog post, corporate website)
  - When two sources disagree, higher evidence level prevails

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

---

## Phase 3: Multi-Pass Draft Writing (FULL pipeline only — not RESEARCH-ONLY)

Writing is inherently sequential at the structural level (you can't parallelize the act of composing a single narrative), but refinement passes on different dimensions CAN run in parallel. Phase 3 uses a **serial draft + parallel refinement + merge** pattern.

### Step 3.1: Structural Draft (Single Writer)

Invoke the primary writing skill via the Skill tool:
- MEDICAL strategy → `medical-imaging-review`
- ACADEMIC or GENERAL strategy → `academic-researcher`

Provide as context: `research-output/phase2-merged.md` and the skill's own template. Output to `research-output/phase3-draft-v1.md` (v1 = structural draft only).

### Step 3.1b: Deep-Read Key Sources (Agent-Parallel, Enrich from Primary Sources)

The structural draft (v1) was written from Phase 2 summaries — second-hand information. This step deep-reads the most important papers to fill in exact numbers, method specifics, and author-stated caveats that summaries may have omitted.

**Context management**: Deep reading loads a 4K skill if done in the main session. Instead, use the same Agent-parallel pattern as Phase 2 — launch background agents with inline instructions. The main session never loads `analyzing-research-papers`. Cost to main session: ~2K for agent launch + ~1-2K for the enriched draft diff.

**How many to deep-read?** ~30-40% of sources, minimum 8, maximum 15. Select by: [A][B] evidence level only → sort by citation count (S2 MCP) → ensure each sub-topic has ≥1 paper represented.

**Launch 2 agents in parallel** (split the paper list evenly). Each agent gets this prompt:

```
You are deep-reading academic papers to extract specific details for a survey draft.
You have access to: Paper Search MCP, S2 MCP, and WebFetch.

For each paper in your list:
1. Paper Search MCP get_paper_details(DOI) → get metadata + abstract
2. S2 MCP → get citation count + TLDR → confirm this paper is high-impact
3. WebFetch the paper URL → extract these 4 things from the full text:
   a) EXACT METRICS: Dice scores, HD95, p-values, sample sizes — specific numbers
   b) METHOD DETAILS: architecture, training protocol, data splits, augmentations
   c) AUTHOR-STATED LIMITATIONS: their own caveats, in their own words
   d) 1-2 CUTABLE QUOTES: with section reference

Return your findings AS TEXT. Structure per paper:
### [Paper Title] (Author, Year)
- **Metrics**: [exact numbers]
- **Methods**: [architecture specifics, training details]
- **Limitations**: [author-stated caveats]
- **Quotes**: "[exact quote]" (Section X)

Do NOT evaluate the paper's quality. Do NOT write prose. Just extract facts.
Do NOT try to write files — return text inline.

Paper list: [paste DOIs/URLs for 4-7 papers]
```

When both agents complete, collect their findings, write to `research-output/phase3-deep-reads.md`, then **clear raw agent output from working memory**.

Finally, apply the findings to v1 → output `phase3-draft-v1-enriched.md`. Fill in missing numbers, add method specifics, insert author-stated caveats and quotes. This is a factual patch — do NOT restructure or rewrite.

### Step 3.2: Parallel Refinement (3 Agents, Background)

Launch 3 Agent tasks IN A SINGLE MESSAGE with `run_in_background: true`. Each refines the draft on a different, independent dimension:

```
Agent A — Prose Quality (academic-writing perspective):
  prompt: |
    Read the draft below. Focus ONLY on language quality:
    - Remove hedging soup (every paragraph ≤2 hedging words: potentially, may, might, could, arguably, perhaps)
    - Replace formulaic transitions (Furthermore, Moreover, Additionally, It is important to note that) with logical flow
    - Strengthen specificity: replace abstract claims with named studies, sample sizes, years
    - Inject authorial voice where the discipline permits
    - Do NOT change structure, facts, citations, or argument. Only language.
    Return the refined prose inline as text.

Agent B — Citation Completeness (literature-review perspective):
  prompt: |
    Read the draft below. Focus ONLY on citation coverage:
    - Are all factual claims backed by a citation?
    - Are there missing seminal works that should be cited?
    - Are any citations attributed to the wrong paper?
    - Check against the merged research notes (phase2-merged.md) for cited-but-not-in-sources
    Return a checklist: [MISSING] for missing citations, [WRONG] for misattributed, [OK] for correct.
    Do NOT rewrite prose. Just return the citation audit.

Agent C — Data & Licensing Audit (medical-imaging domain focus):
  prompt: |
    Read the draft below. Focus ONLY on dataset provenance and licensing:
    For EVERY dataset mentioned in the draft, extract and verify:
    - **Dataset name and source repository** (e.g., TCIA collection ID, Zenodo DOI, GitHub release)
    - **Coverage / FOV**: anatomical regions covered, organs included, any notable exclusions
    - **License type**: CC BY 3.0, CC BY 4.0, CC BY-NC (non-commercial only), custom/proprietary, or unspecified
    - **Commercial use**: explicitly permitted, restricted, or unclear from the license
    - **Key caveats**: pediatric patients excluded? pathology cases excluded? single-vendor only?
    
    Return a structured audit. For each dataset:
    ```
    ### [Dataset Name]
    - **Source**: [URL / DOI / TCIA ID]
    - **Coverage**: [FOV description]
    - **License**: [CC BY 3.0 / CC BY 4.0 / CC BY-NC / Proprietary / Unspecified]
    - **Commercial use**: [Permitted / Restricted / Unclear]
    - **Caveats**: [any limitations on scope, population, or vendor]
    ```
    
    Also flag any dataset mentioned WITHOUT an explicit citation or source link → [UNVERIFIED-DATASET].
    Do NOT rewrite prose. Just return the data audit.
```

### Step 3.3: Merge Refinements

When all 3 agents complete:
1. Apply Agent A's language refinements to v1-enriched → `phase3-draft-v2.md`
2. Apply Agent B's citation fixes to v2 → `phase3-draft-v3.md`
3. Apply Agent C's data notes to v3 → `phase3-draft.md` (final):
   - Add license/caveat annotations to dataset descriptions
   - Flag any [UNVERIFIED-DATASET] items as caveats in the text
4. Record audits: `research-output/phase3-citation-audit.md` (Agent B), `research-output/phase3-data-licensing-audit.md` (Agent C)
5. **Clear raw agent output from working memory after writing files**

**Why parallel works here**: Prose, citations, and data licensing are three orthogonal dimensions — one changes words, one checks references, one verifies dataset provenance. They don't conflict. Running them sequentially would take 3x the wall-clock time with zero quality gain.

### Draft Quality Minimums
- Topic sentences with clear claims
- Every factual claim has at least an inline citation marker
- Method descriptions include limitations
- Comparison table for each major section (if ≥ 3 items to compare)
- **Survey Methodology subsection**: State search period, databases/sources used, keywords, inclusion/exclusion criteria, and the multi-source cross-validation approach
- **Citation audit passed**: All [MISSING] and [WRONG] items from Step 3.2 Agent B resolved
- **Data & licensing audit passed**: All datasets have verified sources and license annotations; [UNVERIFIED-DATASET] items flagged as caveats in the text

### GATE 2: Present the draft summary to the user. "Draft complete — [N] words, [M] sources. Citation audit: [N] missing, [M] misattributed (all fixed). Review before verification?" Do NOT proceed until the user confirms.

### END OF SESSION 1

**Before closing this session:**
1. Verify these files exist on disk: `research-output/phase1-plan.md`, `research-output/phase2-merged.md`, `research-output/phase3-draft.md`
2. Tell the user: "Session 1 complete. All research and draft are saved to `research-output/`. Run `/academic-orchestrator` again and say 'continue from Phase 4' or start Session 2 with: `claude -r "session-1-name" "continue the academic orchestrator from Phase 4"`"
3. Run `/compact` to summarize the conversation before starting Session 2

---

## Session 2: Citations & Formatting

### Starting Session 2

When the user returns for Session 2, you are in a fresh context. Immediately:
1. Read `research-output/phase3-draft.md` and `research-output/phase2-merged.md` (these contain everything you need — do NOT re-read other Phase 2 files unless needed)
2. Do NOT re-run any Phase 1 or 2 work
3. Confirm to user: "Loaded draft ([N] words, [M] sources). Ready for Phase 4."

---

## Phase 4: Citation Management + Source Quality

Invoke `citation-management` skill via the Skill tool.

Input: The inline citation markers and source inventory from `research-output/phase3-draft.md`.

Tasks:
1. For each source, resolve DOI/PMID/arXiv ID → full metadata
2. Generate `references.bib` with all entries validated
3. Check for: missing required fields, duplicate entries, broken DOIs
4. Format BibTeX consistently (standardize field order, author names, capitalization)

**Additional quality checks (performed by the main agent, not citation-management):**
5. **Retraction check**: For the top-10 most-cited or most-critical sources, WebFetch `https://pubmed.ncbi.nlm.nih.gov/?term=[paper title] retraction` or similar. Flag any retracted papers in the citation report
6. **Preprint → published upgrade**: For arXiv preprints, check if a peer-reviewed journal version exists (via Semantic Scholar MCP or CrossRef). If yes → use the published version
7. **Source quality annotation**: Extend the evidence ladder from Phase 2.3 into the citation report. Mark each reference with its evidence level [A/B/C/D]

Output:
- `references.bib` — cleaned, validated BibTeX file
- `research-output/phase4-citation-report.md` — issues found, retraction status, evidence levels

---

## Phase 5: LaTeX Formatting with Self-Healing Compilation

### Step 5.1: Produce .tex File

If the draft is in Markdown:
1. Convert to LaTeX using the target venue's document class or a generic `article` class
2. Write to `manuscript.tex`
3. Ensure all `\cite{}` commands reference keys in `references.bib`

### Step 5.2: Self-Healing Compilation Loop

LaTeX code is brittle — unescaped special characters, missing `\usepackage`, or BibTeX mismatches cause fatal errors. A single diagnostic pass catches some issues, but the only proof of compilability is a successful `pdflatex` run. This step implements a **compile → diagnose → fix → recompile** loop with `max_retries = 3`.

**Loop algorithm:**

```
attempt = 0
while attempt < 3:
    1. Run compilation in Bash:
       pdflatex -interaction=nonstopmode manuscript.tex 2>&1 | tee /tmp/latex-output.log
       bibtex manuscript 2>&1 >> /tmp/latex-output.log
       pdflatex -interaction=nonstopmode manuscript.tex 2>&1 >> /tmp/latex-output.log
       pdflatex -interaction=nonstopmode manuscript.tex 2>&1 >> /tmp/latex-output.log

    2. Check exit code and log:
       if pdflatex returns 0 AND "Fatal error" NOT in log:
           → SUCCESS. Exit loop.
       else:
           attempt += 1
           if attempt == 3:
               → FAIL. Write the last error log to research-output/phase5-compile-errors.log.
                 Report to user: "LaTeX compilation failed after 3 attempts. 
                 Error log saved. Continue with Phase 6 on the last known-good draft?"
                 Do NOT block the pipeline — proceed to Phase 6 with the .md draft as fallback.

    3. Extract the FIRST fatal error from /tmp/latex-output.log:
       - grep for lines containing "! " (LaTeX error marker) or "Fatal error"
       - Extract the 5 lines before and after the error for context
       - Identify error type: undefined control sequence / missing package / 
         bad character escape / BibTeX mismatch / missing file

    4. Feed error to Agent for targeted fix:
       Launch a SINGLE Agent with the error context:
       "The LaTeX compilation failed with this error: [paste error block]. 
        Fix ONLY this specific error in manuscript.tex. Do NOT rewrite the document.
        Common fixes: escape underscores in non-math contexts, add missing \\usepackage{X}, 
        fix unbalanced braces, replace Unicode chars with LaTeX equivalents."

    5. Apply the Agent's fix to manuscript.tex
    6. Retry from step 1
```

**Why this works**: LaTeX errors are usually atomic — one bad `\usepackage`, one unescaped `_`, one mismatched brace. Fixing the first error often resolves cascading errors downstream. The loop targets one error per iteration, which is more reliable than trying to fix everything at once.

### Step 5.3: Final Diagnostic Pass

Once compilation succeeds, invoke `latex-paper-en` skill via the Skill tool for final polish:
- Structure check (abstract/conclusion alignment)
- Language polish (grammar, academic tone)
- Venue formatting compliance (if target specified)

Output: `manuscript.pdf` (compiled) + `manuscript.tex` (compilable source).

### Session 2 Checkpoint: Report to user (FULL strategy only). "LaTeX compilation: [SUCCESS after N attempts / FAILED — see phase5-compile-errors.log]. PDF generated: [yes/no]." For Markdown-only: skip Phase 5 entirely, proceed directly to /compact.

### END OF SESSION 2

**Before closing this session:**
1. Verify these files exist on disk: `manuscript.tex`, `references.bib`, `research-output/phase4-citation-report.md`
2. Tell the user: "Session 2 complete. `manuscript.tex` and `references.bib` are ready. Run `/academic-orchestrator` again and say 'continue from Phase 6' to start verification."
3. Run `/compact`

---

## Session 3: Verification & Review

### Starting Session 3

When the user returns for Session 3, you are in a fresh context. Immediately:
1. Read `manuscript.tex` (this is your primary working file)
2. Read `references.bib` (needed for citation verification)
3. Do NOT re-read Phase 2/3 research files unless a specific claim needs source re-checking
4. Confirm to user: "Loaded manuscript ([N] words, [M] references). Ready for Phase 6 verification."

**Memory discipline for Session 3**: The fact-check skill requires the full manuscript in context. To avoid overflow:
- Read `manuscript.tex` section by section during verification, not all at once
- After each section is verified, write corrections immediately
- Use `references.bib` only for citation lookups — don't hold it all in working memory

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

Apply all corrections to `manuscript.tex`. Record changes in `research-output/phase6-corrections.md`.

### Adversarial Verification (Counter-Evidence Search)

Fact-check verifies "is this claim supported by its cited source?" — but does NOT ask "is there evidence AGAINST this claim?" Adversarial verification closes this gap.

**Process:**
1. Take the top 3-5 HIGH-confidence claims from the fact-check report
2. For each claim, run a targeted search for counter-evidence: "[claim keywords] controversy criticism limitation rebuttal"
3. If counter-evidence is found → downgrade confidence to Medium, add caveat to the manuscript
4. If no counter-evidence → confidence confirmed as HIGH

**Output**: Append an "Adversarial Verification" section to `research-output/phase6-factcheck.md` with the results. This step takes ~5 minutes and catches the most dangerous type of error — consensus claims that the field has moved past.

### GATE 3: Present fact-check summary + adversarial verification to the user.

Show: overall confidence level, number of claims confirmed/unverified/contradicted, and any corrections applied. Ask: "Shall I proceed to peer review with these corrections, or would you like to review the fact-check details first?" Do NOT proceed to Phase 7 until the user confirms.

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
    [paste manuscript.tex content]
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
    [paste manuscript.tex content]
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
    [paste manuscript.tex content]
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

### Post-Review Revision
Address all consensus issues (must-fix) per user's decision at Gate 4. Individual reviewer suggestions are at the user's discretion. Apply revisions to the manuscript.

---

## Phase 8: Final Output

### Step 8.1: Final Validation

Invoke `citation-management` skill to run final validation on `references.bib`.

### Step 8.2: Language Polish

Invoke `writing-clearly-and-concisely` skill (Elements of Style) for final language polish. This is a purely stylistic pass — it improves clarity, concision, and professionalism WITHOUT changing factual content or argument structure. If LaTeX output, invoke `latex-paper-en` skill after language polish for final formatting consistency check.

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

---

## Anti-Patterns

| Don't | Because | Do Instead |
|-------|---------|------------|
| Ask agents to write files | Background agents often lack Write/Bash permissions | Agents return text inline; main session writes files |
| Combine Phase 3 + Phase 6 | Same pass can't reliably catch own hallucinations | Always separate generation and verification |
| Skip Phase 2 merge | Duplicate findings ≠ wasted effort; they're cross-validation | Merge and note agreement/disagreement |
| Run only one research skill | Single source type → blind spots | At minimum deep-research + academic-researcher |
| Skip human gates | User should confirm direction and review drafts | Always gate at Phase 1, Phase 3, Phase 5 |
| Let fact-check find errors → keep going | Errors compound | Fix all CONTRADICTED claims before Phase 7 |
| Launch agents sequentially | They'd run one at a time, defeating the purpose of parallel | Always put all Phase 2 Agent calls in ONE message |
| Use Skill tool for Phase 2 | Skill tool loads instructions into current context, not for delegation | Use Agent tool with tailored prompts for each perspective |

## Quality Heuristics

- **Source diversity**: Aim for ≥ 5 unique domains/hosts per research skill
- **Recency**: Prefer sources from last 3 years for fast-moving fields
- **Citation completeness**: Every factual claim traceable to a source
- **Unverified ceiling**: If > 15% claims are unverified, confidence must be Low
- **Revision loop**: If peer review says Major Revision, loop once; if still Major, flag to user

## Quick Start (for the user)

```
# Session 1 — Research + Draft
# In any project directory, start Claude Code and type:
/academic-orchestrator

# Or say:
"Use the academic orchestrator to write a survey paper on [topic]"

# Follow Phase 1-3. When session ends, run the /compact command.
# All files are saved to research-output/.


# Session 2 — Citations + LaTeX
# In the same directory, start a new session:
/academic-orchestrator
# Then say: "continue from Phase 4"

# Or resume the previous session directly:
claude -r "previous-session-name" "continue the academic orchestrator from Phase 4"


# Session 3 — Verify + Review + Final
# In the same directory, start a new session:
/academic-orchestrator
# Then say: "continue from Phase 6"

# Or:
claude -c "continue the academic orchestrator from Phase 6"
```

The orchestrator reads intermediate files from `research-output/` to pick up where it left off. Each session starts fresh (low context usage) and loads only what it needs from disk. Three sessions total, measured at ~50-75K, ~15-35K, and ~35-55K tokens respectively.

**Markdown-only output**: At Phase 1, say "Markdown only, skip LaTeX." Phase 5 is skipped but the 3-session split remains unchanged — Session 2 does citations only (shorter, ~15K), Session 3 does verification + review as normal. The session split is about context management, not LaTeX dependency.
