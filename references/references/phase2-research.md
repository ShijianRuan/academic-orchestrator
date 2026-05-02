# Phase 2: Multi-Source Parallel Research

## Input Convention
- Reads `research-output/phase1-plan.md` for research questions and strategy
- MCP servers expected: `paper-search` (arXiv, PubMed, Google Scholar, bioRxiv, medRxiv), `semantic-scholar`
- Output: `phase2-deep-research.md`, `phase2-academic-researcher.md`, `phase2-medical-imaging.md` (MEDICAL only), `phase2-merged.md`

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
    - Also call mcp__paper-search__search_google_scholar(query="[sub-question]") for comprehensive coverage. For bio/medical topics, call mcp__paper-search__search_biorxiv + mcp__paper-search__search_medrxiv with the same query
    - Only if ALL MCP calls fail or return empty: fall back to WebSearch + firecrawl_search + exa
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
    - REPORT which tools you used: "[MCP: USED arxiv+pubmed]" or "[FALLBACK: reason]". Do NOT try to write files.

Agent tool call 3 (run_in_background: true) — MEDICAL strategy ONLY:
  subagent_type: "general-purpose"
  description: "medical-imaging: [sub-question]"
  prompt: |
    You are doing medical imaging literature research. Search for: "[sub-question]"
    - REQUIRED: First call mcp__paper-search__search_pubmed AND mcp__paper-search__search_google_scholar(query="[sub-question]")(query="[sub-question]", max_results=10) AND mcp__paper-search__search_medrxiv(query="[sub-question]", max_results=10) AND mcp__paper-search__search_biorxiv(query="[sub-question]", max_results=10). EFFICIENCY: Issue ALL independent MCP calls in ONE message (batch them) to cut wall-clock time by 3-4x. CRITICAL: Pass a real keyword query to each — empty query returns noise.
    - Only if ALL three MCP calls fail or return empty: fall back to firecrawl_search + WebSearch + exa
    - Focus on: clinical validation, Dice/HD95 metrics, public datasets used
    - Find papers: search until returns decline. Minimum: 8 (Quick) / 12 (Standard) / 18 (Exhaustive). Scale to depth from Phase 1. The number is a FLOOR, not a ceiling — return all relevant papers, not just the minimum.
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

