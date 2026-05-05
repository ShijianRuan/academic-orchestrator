# Academic Orchestrator v6.3.0

Multi-phase academic research and writing orchestrator for Claude Code. Chains 12 specialist skills through an 8-phase quality-gated pipeline to produce verified, peer-reviewed papers from a single topic prompt.

## Quick Start

```bash
npx skills add ShijianRuan/academic-orchestrator -g -y
bash ~/.claude/skills/academic-orchestrator/INSTALL.sh
```

Then restart Claude Code and run:

```
/academic-orchestrator
```

## What It Does

| Phase | What Happens |
|-------|-------------|
| 1 | Clarifies scope, formulates research questions, probes MCP availability |
| 2 | Launches 4 parallel search agents (web, academic, domain, multi-database) |
| 3 | Writes a structured draft with deep-read injection and parallel refinement |
| 4 | Validates citations, checks retractions, generates BibTeX |
| 5 | Converts to LaTeX with self-healing compilation |
| 6 | Fact-checks every claim against sources + adversarial verification |
| 7 | 4 parallel peer reviewers + ScholarEval scoring |
| 8 | Language polish + final output package |

Two paths: **RESEARCH-ONLY** (single session, produces a research digest) or **FULL PIPELINE** (3 sessions, produces a verified paper).

## MCP Server Setup

Add to `~/.claude.json`:

```json
{
  "mcpServers": {
    "exa": {
      "type": "http",
      "url": "https://mcp.exa.ai/mcp?exaApiKey=YOUR_KEY"
    },
    "semantic-scholar": {
      "type": "stdio",
      "command": "/opt/homebrew/bin/aira-semanticscholar"
    },
    "arxiv-mcp-server": {
      "type": "stdio",
      "command": "python3",
      "args": ["-m", "arxiv_mcp_server"]
    },
    "pubmed-mcp-server": {
      "type": "stdio",
      "command": "python3",
      "args": ["-m", "pubmedmcp"]
    }
  }
}
```

Optional: `firecrawl` (HTTP), `paper-search` (stdio, for Google Scholar), `zotero` (stdio, for personal library).

## Architecture

See [ARCHITECTURE.md](ARCHITECTURE.md) for pipeline diagrams, MCP tool strategy, and skill dispatch matrix.
