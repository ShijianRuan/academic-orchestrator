# Phase 1: Scope & Protocol

## Input Convention
- No prior files required (this is the first phase)
- Output directory: `research-output/` (created if needed)
- `.phase-state` initialized here
- Output: `research-output/phase1-plan.md` (structured protocol — not a 4-field memo)

---

## Design Principle

Phase 1 is the **load-bearing foundation** of the entire pipeline. A thin plan propagates errors downstream:
- Bad RQs → Phase 2 searches for wrong things → Phase 3 draft has no thesis
- No scope boundary → Phase 3 tries to cover everything → Phase 7 reviewers complain
- No feasibility probe → Phase 2 fails silently because the topic has no literature
- No quality target → Phase 7 reviewers apply implicit standards inconsistently

Every field in `phase1-plan.md` must have a **designated downstream consumer**. If a field has no consumer, it doesn't belong in the plan.

---

## Phase 1: Scope & Protocol

### Step 1.1: Extract Requirements

Ask the user (use AskUserQuestion):

**Core questions:**
- "What is the topic and research question?"
- "What type of output?" — Research digest / Survey paper / Systematic review / Research proposal / Course paper
- "Depth level?" — Quick overview / Standard review / Exhaustive systematic review
- "Which reporting guideline should this follow?" — PRISMA 2020 (systematic reviews/surveys) / STROBE (observational studies) / None (narrative review — no checklist required)
- "Any specific sources, papers, or angles to include/exclude?"

**Anti-scope question** (NEW — sets the OUT boundary):
- "What should this paper explicitly NOT cover?" — specific method families, modalities, time periods, application domains. Examples: "don't cover natural image segmentation," "only CT and MRI, no ultrasound," "exclude pre-2020 papers except for foundational ones."

**Stakeholder question** (NEW — calibrates quality target):
- "Who is this for and what decision will it inform?" — Self-education / Course submission / Advisor review / Conference paper / Journal submission / arXiv preprint

**If the user selects "Research digest"**: route to RESEARCH-ONLY strategy. Single-session, lightweight path.

### Step 1.2: Explore the Research Landscape (embedded methodology, NOT a Skill call)

Before writing research questions, use the **scientific-brainstorming** methodology to explore the topic landscape. This is NOT open-ended chat — it's a structured exploration that produces inputs for Step 1.3.

**Why NOT a Skill call**: `scientific-brainstorming` is designed as an open-ended conversational ideation partner. Invoking it via the Skill tool would load a dialogue protocol that conflicts with Phase 1's structured workflow. The orchestrator applies its core principles (curiosity, challenging assumptions, cross-domain awareness) as a mindset — not as a separate agent.

The five principles (embedded inline, not loaded separately):

```
1. Conversational and Collaborative — ask questions, build on ideas
2. Intellectually Curious — probe what makes this topic worth surveying now
3. Creatively Challenging — push beyond obvious framings
4. Domain-Aware — identify cross-pollination opportunities from adjacent fields
5. Structured yet Flexible — guide with purpose
```

**Exploration focus areas** (3-5 minutes, conversational):
- What makes this topic worth surveying **now**? (recent breakthroughs, controversies, saturation points)
- What are the natural fault lines in the field? (CNN vs Transformer, 2D vs 3D, academic vs clinical)
- What would a reader need to know to understand why this survey exists?
- What existing surveys exist and what do they miss? (this becomes the "Related Work" gap)

**Output**: Do NOT write a file for this step. The output is the mental model you'll use in Step 1.3 to formulate precise RQs.

### Step 1.3: Formulate Research Questions

Transform the exploration into 3-5 research questions. Each RQ must be:

- **Specific**: names concrete methods, datasets, or comparison dimensions — not "what is X?"
- **Answerable from literature**: the answer exists in published papers, not requires new experiments
- **Searchable**: translates directly to a Phase 2 search query
- **Non-redundant**: each RQ covers distinct ground

**Bad RQ**: "How do Vision Transformers compare to CNNs for medical image segmentation?"
→ Too broad. Phase 2 returns noise. Phase 3 draft has no structure.

**Good RQ**: "On the BTCV, AMOS, and Synapse multi-organ CT benchmarks, do hybrid CNN-Transformer architectures (TransUNet, nnFormer, CoTr) achieve statistically higher Dice scores than pure CNN baselines (nnU-Net) under controlled comparison protocols?"
→ Phase 2 has a precise search query. Phase 6 can fact-check the specific numbers. Phase 7 reviewers can evaluate whether the comparison is fair.

**RQ → Search Mapping** (used by Phase 2 agents):
For each RQ, draft the keyword string that Phase 2 agents will use. This ensures RQs are mechanically searchable, not aspirational.

### Step 1.4: Define Scope Boundary (via Skill: literature-review)

**Invoke `Skill(skill="literature-review")` BEFORE this step.** This loads the literature-review SKILL.md into the current session. Use its "Phase 1: Planning and Scoping" methodology directly:

From the loaded methodology, apply:
- PICO framework adapted for surveys → define what's IN scope
- Review type determination (narrative vs. systematic vs. scoping)
- Scope boundary setting: time period, study types, geographic scope
- Inclusion/exclusion criteria BEFORE searching (prevents cherry-picking)

**Why Skill tool here**: literature-review's SKILL.md has a concrete, structured "Phase 1: Planning and Scoping" section with specific scoping protocols. Unlike scientific-brainstorming (which is conversational), this is a procedural methodology that benefits from full context loading. Once loaded, its scoping framework directly populates the scope boundary table below.

**Scope Boundary** (explicit IN/OUT):

| Dimension | IN | OUT | Reason |
|-----------|-----|-----|--------|
| Architecture families | [e.g., CNN, Transformer, Hybrid, Mamba] | [e.g., GANs, Diffusion models] | [why] |
| Modalities | [e.g., CT, MRI] | [e.g., Ultrasound, X-ray, Pathology] | [why] |
| Time range | [e.g., 2020-2026] | [e.g., pre-2020 except foundational] | [why] |
| Task types | [e.g., Semantic segmentation] | [e.g., Instance segmentation, detection] | [why] |
| Evidence level | [e.g., [A][B][C] only] | [e.g., [D] grey literature excluded from claims] | [why] |

**Consumer**: Phase 2.3 merge uses this to filter. Phase 3.2 draft uses this to say "we do NOT cover X — see scope boundary." Phase 7 reviewers can't ding you for missing things you explicitly excluded.

### Step 1.5: Set Quality Target (bound to output type, not venue)

| Output Type | Min Sources (Quick/Std/Exhaustive) | PRISMA Diagram | Statistical Synthesis | Clinical Validation Required |
|-------------|-----------------------------------|----------------|----------------------|------------------------------|
| Research digest | 15/25/40 | No | No | No |
| Survey paper | 20/40/80 | Recommended | If comparing metrics | Optional |
| Systematic review | 30/60/120 | **Required** | **Required** | If clinical topic |
| Course paper | 10/20/30 | No | No | No |

This gives Phase 6 and Phase 7 a standard to measure against.

### Step 1.6: Feasibility Probe (MANDATORY — before GATE 1)

The MCP check is NOT `query="test"`. But the probe strategy differs by MCP type — keyword-based MCPs (arXiv, PubMed) cannot use generic queries and expect relevant results. Semantic MCPs (Semantic Scholar) can.

**Available MCP tools for academic search**:

| MCP Tool | Source | Purpose | Status |
|----------|--------|---------|--------|
| `mcp__semantic-scholar__papers-search-basic` | `aira-semanticscholar` (homebrew) | Semantic search, primary coverage | ✅ |
| `mcp__arxiv-mcp-server__search_papers` | `arxiv-mcp-server` v0.4.12 (pip) | arXiv native search with proper API | ✅ NEW |
| `mcp__pubmed-mcp-server__search_abstracts` | `pubmedmcp` v0.1.4 (pip) | PubMed search with structured abstracts | ✅ NEW |
| `mcp__paper-search__search_pubmed` | `paper-search-mcp` v0.1.3 (pip) | Alternative PubMed | ✅ |
| `mcp__paper-search__search_google_scholar` | `paper-search-mcp` | Google Scholar | ✅ |
| `mcp__paper-search__search_biorxiv` / `search_medrxiv` | `paper-search-mcp` | Preprint servers | ✅ |
| `mcp__paper-search__search_arxiv` | `paper-search-mcp` | **BROKEN** — ignores query params | ❌ DO NOT USE |
| `mcp__exa__web_search_exa` | `exa` MCP | General web search — primary tool for deep-research skill | ✅ |
| `mcp__firecrawl__firecrawl_search` | `firecrawl` MCP | General web search — secondary (credit-limited) | ⚠️ Quota |
| `WebSearch` (built-in) | Claude Code built-in | **BROKEN on DeepSeek** — `tool_choice` API incompatibility | ❌ DeepSeek only |

**Session-environment notes**:
- `WebSearch` works on Anthropic (Claude) models but returns HTTP 400 on DeepSeek models. If the session model is DeepSeek, agents MUST use `mcp__exa__web_search_exa` instead.
- `mcp__firecrawl__firecrawl_search` requires account credits. If credits exhausted, agents fall back to Exa.
- `mcp__semantic-scholar__*` may not load in all sessions (depends on MCP server connectivity at startup).

**Probe procedure**:

1. **Semantic Scholar** (primary coverage check):
   - `mcp__semantic-scholar__papers-search-basic(query="<topic keywords>", limit=5)` → record total hits
   - ≥500 hits → well-covered. 100-499 → niche but researchable. <100 → consider broadening.

2. **arXiv** (via `mcp__arxiv-mcp-server__search_papers`):
   - `mcp__arxiv-mcp-server__search_papers(query="<topic keywords>", max_results=5)` → check relevance
   - 3+/5 relevant → arXiv coverage good. Fallback: if MCP unavailable (new session may need restart), use `WebFetch` with `http://export.arxiv.org/api/query?search_query=all:<t1>+AND+all:<t2>&start=0&max_results=3&sortBy=relevance`

3. **PubMed** (via `mcp__pubmed-mcp-server__pubmed_search_articles` OR `mcp__paper-search__search_pubmed`):
   - Use MeSH-friendly simple terms. Record N/5 relevant.

4. **Evaluate** (advisory, NOT prescriptive):
   - S2 ≥500 hits → topic well-covered. 100-499 → niche but researchable. <100 → warn user.
   - **arXiv probe result is NOT a go/no-go decision.** The probe tests one query pattern; the Agent may use different patterns with different results. Our test showed `"SwinUNETR BTCV"` returns 5/5 relevant but `"medical image segmentation transformer"` returns 0/5. The Agent should know: this MCP matches on exact terms (acronyms, paper names), not natural language.
   - **PubMed probe result is domain-relevance information, not a decision.** If 0/5 relevant → PubMed's MeSH indexing may not cover this CS-heavy topic well. The Agent should try MeSH-friendly queries before giving up.

5. **Record in phase1-plan.md under MCP Status**:
   - Each MCP: probe query, result (relevant/total), total S2 hits
   - **For each MCP, record observed behavior, NOT a command.** Format:
     ```
     | MCP | Probe Query | Result | Observed Behavior | Agent Guidance |
     | S2 | ... | N hits, M/5 relevant | ... | Primary source for broad topic search |
     | arXiv | ... | N/5 relevant | [what pattern worked, what didn't] | [query-pattern suggestion, not "don't use"] |
     | PubMed | ... | N/5 relevant | [what the results were about] | [when it might work better] |
     ```
   - **The Agent Guidance column is advice, not an order.** The Agent sees the phase1-plan §6 table and incorporates it into its own search strategy. The Agent may discover that arXiv works with queries we didn't probe. That's fine — the probe reduces the search space, it doesn't close it.

### Step 1.7: Output the Research Protocol

Write `research-output/phase1-plan.md`. This is a **structured protocol** — each section has a designated downstream consumer.

```markdown
# Research Protocol: [Topic]
*Generated: [date] | Depth: [Quick/Standard/Exhaustive] | Output: [type]*

## 1. Strategy & Routing
- **Strategy**: [MEDICAL/ACADEMIC/GENERAL/RESEARCH-ONLY]
- **Justification**: [1 sentence — why this strategy?]
→ **Consumer**: Phase 2 agent selection, Phase 3 writing skill selection

## 2. Research Questions
For each RQ:
- **RQ[N]**: [full question]
- **Search keywords**: [string for Phase 2 agents]
- **Answer format**: [what kind of answer is expected — comparison table? metric range? taxonomy?]
→ **Consumer**: Phase 2 agent prompts. Phase 6 fact-check claim extraction.

## 3. Scope Boundary
- **IN**: [architecture families, modalities, time range, task types, evidence levels]
- **OUT**: [explicit exclusions with reasons]
→ **Consumer**: Phase 2.3 merge filtering. Phase 3.2 draft scope statement. Phase 7 reviewer calibration.

## 4. Search Strategy
- **Databases**: [arXiv, PubMed, Semantic Scholar, bioRxiv, medRxiv, Google Scholar]
- **Search period**: [YYYY-MM to YYYY-MM]
- **Keywords**: [primary search string + variations]
- **Inclusion criteria**: [relevance, reported quantitative metrics, evidence grade ≥C]
- **Exclusion criteria**: [non-English, pre-2020 except foundational, grey literature for claims]
→ **Consumer**: Phase 2 Step 2.1 embedded in all 4 agent prompts. Phase 2.3 merge dedup.

## 5. Quality Target
- **Output type**: [survey/systematic/digest/course]
- **Depth level**: [Quick/Standard/Exhaustive]
- **Minimum sources**: [N] (from table in Step 1.5)
- **PRISMA required**: [Yes/No]
- **Statistical synthesis required**: [Yes/No]
→ - **Reporting guideline**: [PRISMA 2020 / STROBE / None — selected in Step 1.1]
→ **Consumer**: Phase 3.2 writing — embedded in writing skill invocation as a compliance requirement.

## 6. MCP Status (Feasibility Probe Results)
| MCP | Query | Hits | Status | Phase 2 Adjustment |
|-----|-------|------|--------|-------------------|
| arxiv | [query] | [N] | OK/LOW/FAIL | [none / use S2 fallback / WebFetch arXiv API] |
| pubmed | [query] | [N] | OK/LOW/FAIL | [...] |
| semantic-scholar | [query] | [N] | OK/LOW/FAIL | [...] |
| exa (web) | [query] | [N] | OK/LOW/FAIL | [primary for deep-research agent] |
| firecrawl | [query] | [N] | OK/QUOTA/FAIL | [secondary — skip if quota exhausted] |
→ **Consumer**: Phase 2 Step 2.1 — converts directly to agent prompt MCP sections.

## 7. Stakeholder & Use Case
- **Stakeholder**: [self / course instructor / advisor / journal reviewers]
- **Decision this informs**: [1 sentence]
→ **Consumer**: Phase 7 GATE 4 user-facing summary — calibrates "should we loop back?" decision.
```

### GATE 1

**Before GATE 1, run**: `bash scripts/validate.sh GATE_1 research-output/`. If exit ≠ 0 → fix all FAIL items → re-run → repeat until clean.

Present the plan summary to the user. Do NOT proceed to Phase 2 until the user confirms.

---

## Consumer-Producer Chain (Phase 1 → Downstream)

| phase1-plan.md Section | Consumer Phase | How Consumed |
|------------------------|---------------|--------------|
| §1 Strategy & Routing | Phase 2, 3 | Agent selection, writing skill dispatch |
| §2 Research Questions | Phase 2 | Agent prompt query strings |
| §2 RQ → Search Mapping | Phase 6 | Fact-check claim extraction targets |
| §3 Scope Boundary IN/OUT | Phase 2.3, 3.2, 7 | Merge filter, draft scope statement, reviewer calibration |
| §4 Search Strategy | Phase 2.1 | Embedded in all 4 agent prompts |
| §5 Quality Target | Phase 3, 6, 7 | Draft minimums, fact-check depth, reviewer expectation |
| §6 MCP Probe Results | Phase 2.1 | Per-agent MCP availability + fallback adjustment |
| §7 Stakeholder | Phase 7 GATE 4 | Loop-back decision calibration |

<!-- PHASE_1_SCOPE_REFERENCE_COMPLETE: 2026-05-04 -->
