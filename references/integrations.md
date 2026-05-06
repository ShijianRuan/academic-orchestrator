# External Skill Integrations

The orchestrator integrates with K-Dense-AI scientific-agent-skills for enhanced capabilities. All integrations are optional — the pipeline runs without them, but quality degrades gracefully.

## Installation

```bash
npx skills add K-Dense-AI/scientific-agent-skills -y
```

**Prerequisites**: Python 3.11+, `uv` package manager.

## Integrated Skills

### paper-lookup — Phase 2 (4th parallel agent)
- **What**: Search 10 academic databases (PubMed, PMC, bioRxiv, medRxiv, arXiv, OpenAlex, Crossref, Semantic Scholar, CORE, Unpaywall) via REST APIs
- **Why**: Complements our existing 3 MCP-based agents with databases they don't cover (CORE full text, Unpaywall OA, OpenAlex 250M works, Crossref metadata)
- **How**: 4th Agent in Phase 2 parallel search, `run_in_background: true`
- **Output**: `research-output/phase2-paper-lookup.md`
- **Fallback**: Use MCP paper-search (arxiv/pubmed/scholar/biorxiv) only — narrower coverage
- **Quality gain**: Discovers papers the other 3 agents miss, especially open-access full texts and papers outside biomedicine (CS, physics, engineering)

### scientific-critical-thinking — Phase 6 (Step 6.6)
- **What**: GRADE evidence grading, bias detection (confirmation, selection, p-hacking), logical fallacy identification, claim-evidence mismatch analysis
- **Why**: Fact-check only verifies "is claim supported?" — doesn't assess source quality, bias, or logical validity of argument chains
- **How**: Invoked via Skill tool after Phase 6 corrections are applied, before GATE 3
- **Output**: `research-output/phase6-critical-thinking.md`
- **Fallback**: Skip; fact-check alone provides basic verification
- **Quality gain**: Catches p-hacking, overgeneralization, and GRADE-level evidence weaknesses that fact-check alone misses

### peer-review (K-Dense) — Phase 7 (4th reviewer)
- **What**: 7-stage peer review with CONSORT/STROBE/PRISMA checklists, statistical rigor assessment, image integrity, ethics, reproducibility
- **Why**: Our 3 reviewers (Methodologist, Domain Expert, Editor) focus on different dimensions. K-Dense adds structured checklist-based evaluation of reporting standards, statistical methods, and reproducibility — dimensions our reviewers don't systematically cover.
- **How**: 4th Agent in Phase 7 parallel review, `run_in_background: true`
- **Output**: `research-output/phase7-reviewer-d.md`
- **Fallback**: 3 reviewers only — adequate but missing reporting-standards and reproducibility dimensions
- **Quality gain**: Systematic CONSORT/STROBE/PRISMA compliance, statistical rigor audit, reproducibility assessment

### scholar-evaluation — Phase 7.5 (MANDATORY)
- **What**: ScholarEval 8-dimension quantitative scoring framework (each dimension 1-5)
- **Why**: Qualitative peer reviews describe issues but don't quantify. Scholar Evaluation provides numeric scores that enable tracking improvement across revisions and benchmarking against publication standards. Without quantitative scores, you cannot objectively measure whether a revision improved the manuscript — you only have reviewer opinions.
- **How**: Invoked via Skill tool after Phase 7 reviews are merged, before GATE 4
- **Output**: `research-output/phase7-scholar-eval.md`
- **Fallback**: None — MANDATORY. GATE 4 Layer 1 checks for this file.
- **Quality gain**: Quantitative baseline for revision quality tracking; identifies which dimensions are weakest; enables objective before/after comparison when revising

## Context Management

These integrations generate additional intermediate files. Dispose of them from memory at the standard checkpoints:

| File | Dispose After |
|------|--------------|
| phase2-paper-lookup.md | Phase 2.3 merge |
| phase6-critical-thinking.md | GATE 3 (retain for Phase 7 reviewer context) |
| phase7-reviewer-d.md | Phase 7.2 merge |
| phase7-scholar-eval.md | GATE 4 |

## Sandboxing & Security

All 4 integrated skills are **instruction-only** — they guide agent behavior through SKILL.md instructions. They do not require executing third-party Python scripts or installing packages. The agent uses existing tools (WebFetch, Bash, Write) to follow the skill's methodology.

- **paper-lookup**: Uses WebFetch/curl for REST API calls to 10 databases. No code execution.
- **peer-review**: Pure evaluation methodology. No code execution.
- **scientific-critical-thinking**: Pure evaluation methodology (GRADE/Cochrane frameworks). No code execution.
- **scholar-evaluation**: Pure evaluation methodology (ScholarEval framework). Optional `calculate_scores.py` is not required.

All skills run within Claude Code's default Bash sandbox when tools are invoked.

## Skill Availability Check

At Phase 1 (scope), check if K-Dense skills are installed:

```bash
ls ~/.claude/skills/paper-lookup/SKILL.md 2>/dev/null && echo "K-Dense: AVAILABLE" || echo "K-Dense: NOT INSTALLED"
```

Record availability in `phase1-plan.md` under MCP Status. The dispatch matrix handles both paths — if installed, use enhanced path; if not, use default path.
