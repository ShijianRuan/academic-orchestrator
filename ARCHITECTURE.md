# Academic Orchestrator v6.3.0 — Architecture

## Pipeline Overview

```mermaid
flowchart TB
    subgraph Session1["Session 1 — Research + Draft (~60K)"]
        P1["Phase 1: Scope & Protocol"] --> G1{"GATE 1"}
        G1 --> P2["Phase 2: 4-Agent Parallel Search"]
        P2 --> P3["Phase 3: Multi-Pass Draft Writing"]
        P3 --> G2{"GATE 2"}
    end

    subgraph Session2["Session 2 — Citations + Format (~25K)"]
        P4["Phase 4: Citation Management"] --> P5["Phase 5: LaTeX Compilation"]
    end

    subgraph Session3["Session 3 — Verify + Review + Final (~50K)"]
        P6["Phase 6: Fact-Check + Adversarial"] --> G3{"GATE 3"}
        G3 --> P7["Phase 7: 4-Reviewer Peer Review"]
        P7 --> P75["Phase 7.5: ScholarEval"]
        P75 --> G4{"GATE 4"}
        G4 --> P8["Phase 8: Final Output"]
        P8 --> G5{"GATE 5"}
    end

    G2 --> Session2
    Session2 --> Session3
    G5 --> Output["manuscript.pdf + VERIFICATION_STATUS.md"]
```

## Phase 2: Parallel Research Detail

```mermaid
flowchart LR
    Plan["phase1-plan.md"] --> A1 & A2 & A3 & A4

    subgraph Agents["4 Parallel Agents"]
        A1["deep-research<br/>Exa + Firecrawl<br/>Web / News / Industry"]
        A2["academic-researcher<br/>S2 + arXiv + PubMed + Scholar<br/>Multi-source Academic"]
        A3["medical-imaging<br/>arxiv + pubmed + zotero<br/>Domain Full-text + Zotero"]
        A4["paper-lookup<br/>10 Databases<br/>Cross-DB Verification + OA"]
    end

    A1 & A2 & A3 & A4 --> PRISMA["PRISMA Flow Documentation"]
    PRISMA --> Merge["Cross-Validation & Merge"]
    Merge --> Chain["Citation Chaining (S2 MCP)"]
    Chain --> phase2merged["phase2-merged.md"]
```

## MCP Tool Strategy (v6.3)

```mermaid
flowchart TB
    subgraph Principle["Design Principle"]
        P["Skill defines tools. Orchestrator does NOT override."]
    end

    subgraph DR["deep-research"]
        DR_T["Skill SKILL.md → Exa + Firecrawl"]
    end

    subgraph AR["academic-researcher"]
        AR_T["Orchestrator prompt → S2 + arXiv + PubMed + Scholar"]
        AR_P["PubMed: BOTH pubmed-mcp-server AND paper-search-pubmed"]
    end

    subgraph MI["medical-imaging"]
        MI_T["Skill allowed-tools → arxiv + pubmed + zotero"]
        MI_N["NOT paper-search MCPs (was override, now fixed)"]
    end

    subgraph PL["paper-lookup"]
        PL_T["Orchestrator prompt → 10 REST APIs"]
    end

    subgraph WS["WebSearch Status"]
        WS_A["Anthropic API → ✅ works"]
        WS_D["DeepSeek API → ❌ broken (v2.1.126 deferred tools)"]
        WS_F["Fix: Exa MCP replaces WebSearch everywhere"]
    end
```

## Tool Choice Matrix

| Purpose | Primary | Fallback |
|---------|---------|----------|
| arXiv | `arxiv-mcp-server` | Semantic Scholar |
| PubMed | `pubmed-mcp-server` | `paper-search` PubMed |
| Google Scholar | `paper-search` | — (unique) |
| General Web | Exa MCP | Firecrawl (quota) |
| Semantic Academic | Semantic Scholar | Exa web search |

## Phase 3: Multi-Pass Writing

```mermaid
flowchart TB
    Merged["phase2-merged.md"] --> R1["3.1: Structure Reads<br/>5-8 papers → field taxonomy"]
    R1 --> R2["3.2: Structural Draft<br/>Skill(medical-imaging-review)"]
    R2 --> R3a["3.3a: Assess Draft Needs<br/>Identify gaps → deep-read-plan.md"]
    R3a --> R3b["3.3b: Deep Read Injection<br/>Parallel agents → deep-reads.md"]
    R3b --> R4["3.4: Parallel Refinement (3 agents)"]

    subgraph Refine["Refinement Agents"]
        RA["Prose + Narrative"]
        RB["Citation Audit"]
        RC["Data Compliance"]
    end

    R4 --> Refine
    Refine --> R5["3.5: Merge → phase3-draft.md"]
```

## Phase 6-7: Verification & Review

```mermaid
flowchart LR
    subgraph P6["Phase 6"]
        FC["Skill(fact-check)<br/>4-phase verification"]
        AV["Adversarial Search<br/>counter-evidence"]
        GA["Evidence Grade Audit<br/>[A/B/C/D] cross-ref"]
    end

    subgraph P7["Phase 7"]
        RV1["Methodologist"]
        RV2["Domain Expert"]
        RV3["Editor"]
        RV4["K-Dense Peer Review"]
    end

    P6 --> P7
    RV1 & RV2 & RV3 & RV4 --> Consensus["Merge Consensus<br/>2+ agree → required fix"]
    Consensus --> ScholarEval["ScholarEval 8-dimension"]
```

## Skill Dispatch Matrix

| Phase | Skill | Method |
|-------|-------|--------|
| 1 | literature-review | Skill + Agent |
| 2 | deep-research, academic-researcher, medical-imaging, paper-lookup | Agent (bg) x4 |
| 3.2 | medical-imaging-review | Skill (writing) |
| 3.4 | — | Agent (bg) x3 (prose, citation, data) |
| 4 | citation-management | Skill + orchestrator additions |
| 5 | latex-paper-en | Skill + Bash |
| 6 | fact-check + scientific-critical-thinking | Skill + orchestrator additions |
| 7 | peer-review (4 reviewers) | Agent (bg) x4 |
| 7.5 | scholar-evaluation | Skill |
| 8 | citation-management + writing-clearly-and-concisely | Skill + Agent (bg) |

## Bundled Skills

```
skills/
├── deep-research/          — Exa + Firecrawl web search
├── academic-researcher/    — Paper analysis methodology
├── medical-imaging-review/ — 7-phase medical imaging writing
├── citation-management/    — BibTeX + validation
├── fact-check/             — 4-phase verification
├── peer-review/            — Structured manuscript review
├── literature-review/      — Systematic review methodology
├── writing-clearly-and-concisely/ — Strunk language polish
└── latex-paper-en/         — LaTeX compilation + formatting
```

## Compatibility

| Model | WebSearch | MCP Tools | Notes |
|-------|-----------|-----------|-------|
| Anthropic (Claude) | ✅ | ✅ | Full native support |
| DeepSeek (v4-pro) | ❌ | ✅ | WebSearch replaced by Exa MCP |

## Installation

```bash
npx skills add ShijianRuan/academic-orchestrator -g -y
bash ~/.claude/skills/academic-orchestrator/INSTALL.sh
```

## External Skills (npx skills registry)

These skills are installed via `npx skills add` and stored in Claude Code's internal registry (NOT in `~/.claude/skills/`). They are available at runtime but SKILL.md files are not accessible for bundling.

| Skill | Source | Fallback if Missing |
|-------|--------|---------------------|
| paper-lookup | K-Dense-AI/scientific-agent-skills | Use MCP paper-search only |
| scientific-critical-thinking | K-Dense-AI/scientific-agent-skills | Skip; fact-check alone |
| scholar-evaluation | K-Dense-AI/scientific-agent-skills | Skip; qualitative reviews only |

Install:
```bash
npx skills add K-Dense-AI/scientific-agent-skills -g -y
```
