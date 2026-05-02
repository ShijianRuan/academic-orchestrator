# Phase 1: Scope & Route

## Input Convention
- No prior files required (this is the first phase)
- Output directory: `research-output/` (created if needed)
- `.phase-state` initialized here

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

### Step 1.4: MCP Availability Check

Before launching Phase 2 agents, verify that required MCP tools are available. The check is lightweight — one call per MCP:

1. Test `mcp__paper-search__search_arxiv(query="test", max_results=1)`
2. Test `mcp__semantic-scholar__papers-search-basic(query="test", limit=1)`
3. Record results in `research-output/phase1-plan.md` under an "MCP Status" section

**If ALL primary MCPs fail**: Warn the user with AskUserQuestion:
"MCP servers (paper-search, semantic-scholar) are not available. Phase 2 will fall back to web search — search quality and academic coverage will degrade significantly. Continue anyway?"

**If SOME fail**: Note which MCPs are missing. Adjust Phase 2 agent prompts:
- Remove REQUIRED MCP calls for unavailable servers
- Upgrade the FALLBACK WebSearch to PRIMARY for that agent
- Note in the merged report which sources were unavailable

**If ALL pass**: Proceed normally. Phase 2 agents will use full MCP coverage.

### GATE 1: Present the plan to the user. Do NOT proceed to Phase 2 until the user confirms.

---

