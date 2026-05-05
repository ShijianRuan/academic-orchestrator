# Academic Orchestrator — Architecture

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

## Phase 2: Parallel Research

```mermaid
flowchart LR
    Plan["phase1-plan.md"] --> A1 & A2 & A3 & A4

    subgraph Agents["4 Parallel Agents"]
        A1["deep-research<br/>Web / News / Industry"]
        A2["academic-researcher<br/>Multi-source Academic"]
        A3["medical-imaging<br/>Domain Literature (MEDICAL)"]
        A4["paper-lookup<br/>Cross-Database Verification"]
    end

    A1 & A2 & A3 & A4 --> PRISMA["PRISMA Flow"]
    PRISMA --> Merge["Cross-Validation & Merge"]
    Merge --> Chain["Citation Chaining"]
    Chain --> phase2merged["phase2-merged.md"]
```

## MCP Tool Strategy

**Principle**: Each agent uses the tools defined by its own skill. The orchestrator provides search guidance but does not override tool choices.

| Agent | Tools Defined By | Primary Tools |
|-------|-----------------|---------------|
| deep-research | skill SKILL.md | Exa + Firecrawl |
| academic-researcher | orchestrator prompt | S2 + arXiv + PubMed + Scholar |
| medical-imaging | skill allowed-tools | arxiv + pubmed + zotero |
| paper-lookup | orchestrator prompt | 10-database REST APIs |

### Tool Choice Matrix

| Purpose | Primary | Fallback |
|---------|---------|----------|
| arXiv | `arxiv-mcp-server` | Semantic Scholar |
| PubMed | `pubmed-mcp-server` + `paper-search` PubMed | Exa web search |
| Google Scholar | `paper-search` | — (unique) |
| General Web | Exa MCP | Firecrawl |
| Semantic Academic | Semantic Scholar | Exa web search |

### Compatibility

| Model | WebSearch | MCP Tools |
|-------|-----------|-----------|
| Anthropic (Claude) | ✅ | ✅ |
| DeepSeek | ❌ (use Exa instead) | ✅ |

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
| 3.2 | medical-imaging-review | Skill |
| 3.4 | — | Agent (bg) x3 |
| 4 | citation-management | Skill |
| 5 | latex-paper-en | Skill |
| 6 | fact-check + scientific-critical-thinking | Skill |
| 7 | peer-review (4 reviewers) | Agent (bg) x4 |
| 7.5 | scholar-evaluation | Skill |
| 8 | citation-management + writing-clearly-and-concisely | Skill + Agent (bg) |

## Bundled Skills

```
skills/
├── deep-research/                 — Web search (Exa + Firecrawl)
├── academic-researcher/           — Paper analysis methodology
├── medical-imaging-review/        — 7-phase medical imaging writing
├── citation-management/           — BibTeX + validation
├── fact-check/                    — 4-phase verification
├── peer-review/                   — Structured manuscript review
├── literature-review/             — Systematic review methodology
├── writing-clearly-and-concisely/ — Language polish
├── latex-paper-en/                — LaTeX compilation
├── paper-lookup/                  — 10-database unified search
├── scientific-critical-thinking/  — Evidence grading + bias detection
└── scholar-evaluation/            — 8-dimension quantitative scoring
```

Skills 10-12 are from [K-Dense-AI/scientific-agent-skills](https://github.com/K-Dense-AI/scientific-agent-skills). They are bundled here for portability but can also be installed independently via `npx skills add K-Dense-AI/scientific-agent-skills -g -y`.
