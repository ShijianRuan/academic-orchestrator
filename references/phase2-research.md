# Phase 2: Multi-Source Parallel Research

## Input Convention
- Reads `research-output/phase1-plan.md` for research questions and strategy
- MCP servers expected: `paper-search` (arXiv, PubMed, Google Scholar, bioRxiv, medRxiv), `semantic-scholar`
- Output: `phase2-deep-research.md`, `phase2-academic-researcher.md`, `phase2-medical-imaging.md` (MEDICAL only), `phase2-paper-lookup.md`, `phase2-merged.md`

---

## Phase 2: Multi-Source Parallel Research

### Why Parallel (Not Sequential)

Each skill uses a disjoint source pool — they search different corners of the internet:
- `deep-research`: Firecrawl + Exa → general web, news, industry reports, blogs
- `academic-researcher`: Scholarly sources → peer-reviewed papers, structured analysis, citations
- `medical-imaging-review`: arXiv + PubMed + Zotero → domain-specific literature (MEDICAL only)

Running them sequentially is not just slower — it introduces bias. If deep-research runs first and finds X, academic-researcher may anchor on X and miss Y. Running them blind to each other, then cross-validating, catches more and overweights less.

**Cost-benefit**: 2-3 parallel agents instead of 1, but wall-clock time is ~the slowest single agent (60-90s), not the sum. Coverage gain is substantial — our test showed Agent 1 found physics-inspired attention mechanisms and frequency-domain approaches that Agent 2 missed, while Agent 2 found a specific ICLR paper and implementation details that Agent 1 missed. Only overlap: sparse attention / Focus trend. Combined coverage was ~3x either alone.


**User-facing progress**: After launching agents, output:
"━━━ Phase 2: Multi-Source Research ━━━
 3 parallel agents launched (deep-research, academic-researcher, medical-imaging)."
After each agent completes: "[N/3 agents complete]"
After all complete, output the Phase 2 Complete summary with source counts and MCP status.
Do NOT show raw agent completion notifications to the user.

### Step 2.1: Launch Agents in a Single Message

**Critical**: Launch ALL agents by putting multiple Agent tool calls in ONE message. This is what makes them truly concurrent — each gets its own context window and runs independently. Use `run_in_background: true` so the main session is not blocked.

**Before launching**: Read `research-output/phase1-plan.md` and extract:
- **§2 Research Questions**: each RQ's search keywords → becomes the agent query string
- **§4 Search Strategy**: databases, keywords, time range, inclusion/exclusion criteria → embedded in agent prompts as search constraints
- **§6 MCP Status (Feasibility Probe Results)**: for each MCP, status (OK/LOW/FAIL) → adjust agent REQUIRED/FALLBACK instructions. LOW → reduce max_results for that MCP but still try. FAIL → remove REQUIRED, upgrade FALLBACK to PRIMARY.

If you skip this step and use generic queries, the search will be disconnected from the Phase 1 protocol and the scope boundary will be ignored.

**Skill content**: Each agent prompt below includes the task-specific search instructions. When launching agents, also embed the full methodology from the corresponding skill's SKILL.md:
- deep-research agent: prepend `~/.claude/skills/deep-research/SKILL.md`
- academic-researcher agent: prepend `~/.claude/skills/academic-researcher/SKILL.md`
- medical-imaging agent: prepend `~/.claude/skills/medical-imaging-review/SKILL.md`

The skill methodology provides the general approach; the prompts below provide the task-specific focus.

**Agent prompt construction** (MANDATORY — wire Phase 1 into every agent):

Each agent prompt MUST include three sections populated from `research-output/phase1-plan.md`. These are **search guidance, not exclusion filters** — the boundary filtering happens at Phase 2.3 merge, not at Phase 2.1 search:

```
## Search Guidance (from Phase 1 Protocol §3-4-6)
### Focus Areas (NOT exclusion filters)
[INSERT §3 IN column from phase1-plan.md — these are the architecture families, modalities, and time periods to FOCUS on. Do NOT exclude papers that cross boundaries. Flag them for merge-stage review.]

### Suggested Search Strategy
[INSERT §4 Search Strategy from phase1-plan.md — start with these keywords and databases. Follow promising leads even if they use different terminology.]

### MCP Observations (probe results from Phase 1)
[INSERT §6 MCP Probe table from phase1-plan.md — "Agent Guidance" column. This is what we observed, not what you must do.]

### Quality Rules (embedded from deep-research methodology)
- **Every claim needs a source**: No unsourced assertions. Every factual claim must cite a specific paper or URL.
- **Cross-reference**: If only ONE source supports a finding, mark it as `[SINGLE-SOURCE]`. Findings confirmed by 2+ independent sources are `[CROSS-VERIFIED]`.
- **Confidence labels**: Label each finding as HIGH (3+ independent sources agree) / MEDIUM (2 sources) / SINGLE (1 source).
- **Separate fact from inference**: Explicitly label estimates, projections, and opinions — never present them as established facts.
- **Acknowledge gaps**: If no sources found for a sub-topic, say "insufficient data found" — never fabricate.
- **Recency preference**: Prefer sources from the last 2 years unless citing foundational work (e.g., U-Net 2015).
```

**Why guidance, not constraints**: The old design (pre-Phase 1 protocol) had no scope boundary in agent prompts — agents searched freely, and Phase 2.3 merge did the filtering. This had higher recall (fewer missed papers) at the cost of some noise. Adding exclusion filters to search would reverse this: higher precision but potentially missing cross-boundary discoveries. The filter belongs at merge, not at search. The Phase 1 guidance helps the agent start with a focused strategy but does not prevent it from finding unexpected relevant work.

For each sub-question from Phase 1, launch:

```
Message to user: "Launching N parallel research agents for: [sub-question]..."

Agent tool call 1 (run_in_background: true):
  subagent_type: "general-purpose"
  description: "deep-research: [sub-question]"
  prompt: |
    You are doing multi-source web research. Search for: "[sub-question]"
    
    ## Search Guidance (from Phase 1 Protocol)
    ### Focus Areas
    [INSERT §3 IN column from phase1-plan.md — focus here, flag cross-boundary papers for merge review]
    ### Suggested Search Strategy
    [INSERT §4 from phase1-plan.md — start here, follow promising leads]
    ### MCP Observations
    [INSERT §6 Agent Guidance column from phase1-plan.md]
    
    - **Tool strategy**: Your embedded deep-research SKILL.md (prepended above) defines your search tools. Use them.
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
    
    ## Search Guidance (from Phase 1 Protocol)
    ### Focus Areas
    [INSERT §3 IN column from phase1-plan.md — focus here, flag cross-boundary papers for merge review]
    ### Search Strategy
    [INSERT §4 from phase1-plan.md — start with these keywords, follow promising leads]
    ### MCP Tool Strategy
    [INSERT §6 Agent Guidance column from phase1-plan.md. Tool strategy below.]
    
    **Academic search tools** (in priority order):
    - PRIMARY: mcp__semantic-scholar__papers-search-basic(query="[sub-question]", limit=15). Semantic search. Best for broad topic queries. Indexes all arXiv papers.
    - arXiv: mcp__arxiv-mcp-server__search_papers(query="[sub-question]", max_results=10). Native arXiv MCP with proper search, download, and read capabilities. Use for CS/ML preprints.
    - PubMed: Call BOTH mcp__pubmed-mcp-server__search_abstracts AND mcp__paper-search__search_pubmed. Batch them in ONE message. Merge results, dedup by title/DOI. Use MeSH-friendly terms.
    - Scholar: mcp__paper-search__search_google_scholar(query="[sub-question]") for comprehensive coverage.
    - Preprints: mcp__paper-search__search_biorxiv + mcp__paper-search__search_medrxiv for bio/medical preprints.
    - FALLBACK: mcp__exa__web_search_exa (only if ALL primary MCP calls fail).
    
    **Note**: mcp__paper-search__search_arxiv is a known-broken wrapper — use mcp__arxiv-mcp-server__search_papers instead. S2 is always available as backup for arXiv coverage.
    - Focus on: peer-reviewed papers, methodology, experimental results, citations
    - Find papers: search until returns decline. Minimum: 8 (Quick) / 12 (Standard) / 18 (Exhaustive). Scale to depth from Phase 1. The number is a FLOOR, not a ceiling — return all relevant papers, not just the minimum.
    - Return your findings AS TEXT in your response. Structure them as:
      ## [Sub-question] — Academic Perspective
      ### Key Papers
      1. [Paper title] ([Year]) — [1-line finding]. DOI/URL: [link]
      2. ...
      ### Methodological Themes
      [patterns across papers]
      ### Research Gaps
      [what's missing]
    - REPORT which tools you used: "[MCP: USED s2+arxiv+pubmed]" or "[FALLBACK: reason]". Do NOT try to write files.

Agent tool call 3 (run_in_background: true) — MEDICAL strategy ONLY:
  subagent_type: "general-purpose"
  description: "medical-imaging: [sub-question]"
  prompt: |
    You are doing medical imaging literature research. Search for: "[sub-question]"
    - **Tool strategy**: Your embedded medical-imaging-review SKILL.md (prepended above) defines your allowed-tools (arxiv-mcp-server, pubmed-mcp-server, zotero). Use them. Issue ALL independent MCP calls in ONE message (batch them) to cut wall-clock time by 3-4x.
    - Focus on: clinical validation, Dice/HD95 metrics, public datasets used
    - Find papers: search until returns decline. Minimum: 8 (Quick) / 12 (Standard) / 18 (Exhaustive). Scale to depth from Phase 1. The number is a FLOOR, not a ceiling — return all relevant papers, not just the minimum.
    - Return your findings AS TEXT in your response. Structure them as:
      ## [Sub-question] — Medical Imaging Perspective
      ### Key Papers
      1. [Paper title] ([Year]) — Method: [method], Dice: [score], Dataset: [dataset]. URL: [link]
      ...
    - REPORT which tools you used: "[MCP: USED pubmed+medrxiv+biorxiv]" or "[FALLBACK: reason]". Do NOT try to write files.
```

Agent tool call 4 (run_in_background: true):
  subagent_type: "general-purpose"
  description: "paper-lookup: [sub-question]"
  prompt: |
    You are doing comprehensive multi-database literature search using the Paper Lookup skill. Search for: "[sub-question]"
    - Use the paper-lookup skill to query across 10 academic databases
    - Cross-database queries: PubMed + OpenAlex + Semantic Scholar for comprehensive literature search
    - Also query bioRxiv/medRxiv for preprints, Unpaywall for open access PDFs
    - Focus on: peer-reviewed papers, preprints, citation data, open access availability
    - Find papers: search until returns decline. Minimum 10 papers.
    - Return your findings AS TEXT in your response. Structure them as:
      ## [Sub-question] — Multi-Database Perspective
      ### Key Papers (with database sources)
      1. [Title] ([Year]) — [finding]. Source: [database]. DOI: [doi]
      ...
      ### Databases Queried
      [list each database with specific endpoints used]
      ### Cross-Database Coverage
      [papers found across multiple databases — HIGH confidence]
      ### Open Access Availability
      [which papers have OA PDFs via Unpaywall/CORE]
    - REPORT: "[Paper Lookup: USED pubmed+openalex+s2+biorxiv+unpaywall]" or "[FALLBACK: reason]". Do NOT try to write files.

### Step 2.2: Collect Results, Write to Disk, Clear from Memory

When ALL agents complete, for each agent:
1. Extract the full findings from the completion notification text
2. Write to its file immediately — do NOT truncate or summarize: `research-output/phase2-deep-research.md`, `research-output/phase2-academic-researcher.md`, `research-output/phase2-medical-imaging.md` (if MEDICAL), `research-output/phase2-paper-lookup.md`
3. **After writing**: clear the raw agent output from working memory. The files on disk are the authoritative record

**Why the main session writes files, not agents**: Background agents may lack Write/Bash permissions. Main session persists them. 

**Why dispose of raw output**: Three agent results can total 30-50K tokens. Keeping them in working memory alongside the orchestrator, writing skill, and draft would exhaust the context budget before Phase 3 even begins. The files are on disk — subsequent phases read only the merged synthesis.

### Step 2.3: Merge & Cross-Validate (from files only)

#### Step 2.3a: PRISMA Flow Documentation (MANDATORY — before merge)

After ALL 4 agents complete but BEFORE merging their results, document the screening process. This embeds the PRISMA methodology from the literature-review skill without invoking it as a full Skill:

1. Read all 4 agent output files from disk
2. Count and record:
   - Records identified per agent (deep-research: N, academic-researcher: M, etc.)
   - Duplicates removed (cross-agent dedup by DOI and title similarity)
   - Records screened (unique records after dedup)
   - Records excluded with reasons (out-of-scope, no metrics, non-English, etc.)
   - Final records included in synthesis
3. Write `research-output/phase2-prisma.md`:

```markdown
# PRISMA Flow Diagram: [Topic]

## Identification
| Agent | Records |
|-------|---------|
| deep-research | N |
| academic-researcher | M |
| medical-imaging-review | P |
| paper-lookup | Q |
| **Total identified** | N+M+P+Q |

## Screening
- Duplicates removed: D
- Records screened: (N+M+P+Q) - D
- Records excluded: E
  - Out of scope: E1
  - No quantitative metrics: E2
  - Non-English: E3
  - Other: E4

## Included
- Studies included in synthesis: S
```

4. This file is a **GATE 2 Layer 1 dependency**. Its absence means the screening process was undocumented and irreproducible.

#### Step 2.3b: Cross-Validate & Produce Merged Notes

Read phase2-deep-research.md, phase2-academic-researcher.md, phase2-medical-imaging.md, and phase2-paper-lookup.md from disk. Do NOT use the raw agent completion text still in conversation memory — read the files. Then produce `research-output/phase2-merged.md`:

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

**Paper selection matrix** (select at least 1 paper from EACH dimension, minimum 3 papers total):

| Dimension | Criteria | Examples | Why |
|-----------|----------|----------|-----|
| **Citation anchor** | Highest citation count in inventory | Litjens 2017 (13K), nnU-Net (5K+) | Forward search finds everything built on seminal work |
| **Methodological diversity** | Representative of different architecture families | Best CNN paper + best Transformer paper + best SAM paper | Avoids over-representing one family in citation graph |
| **Temporal spread** | One older seminal (>3 yrs) + one recent high-impact (<2 yrs) | nnU-Net 2021 + MedSAM 2024 | Captures both foundational roots and latest branches |

For EACH selected paper:
1. Use `mcp__semantic-scholar__papers-citations` (forward search, limit=10) → find papers citing it
2. Use `mcp__semantic-scholar__papers-references` (backward search, limit=10) → find papers it cites
3. Filter results: keep only papers that are (a) relevant to the research questions AND (b) NOT already in the Source Inventory

**Minimum completion standard**: At least 3 papers forward-searched AND 2 papers backward-searched. Fewer than this → Phase 2.4 is incomplete → GATE 1 cannot pass (return to complete). Record which papers were searched and which were not, with reason.

**Verification**: The Citation Graph Discoveries section MUST list ≥3 newly found papers. If fewer than 3 are found after searching all selected papers → document that the search was exhaustive but the citation graph yielded limited new discoveries. Either way, the search must be COMPLETE, not partial.

4. **MANDATORY**: For every newly discovered paper that is relevant to the research questions, add it to the Source Inventory table in `phase2-merged.md` with full metadata (authors, year, venue, evidence grade, DOI/URL). Do NOT leave papers in the "Citation Graph Discoveries" section without promoting them to the inventory — our test found this creates [UNVERIFIED-SOURCE] flags in Phase 3.4 when the draft cites these papers but the citation audit can't find them in the inventory.
5. Append a "Citation Graph Discoveries" section listing all newly found papers with the searching paper and direction, AND a cross-reference to their new Source Inventory row number.

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

