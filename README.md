# Academic Orchestrator v5.2.0

Multi-phase academic research and writing orchestrator for Claude Code. Two paths: RESEARCH-ONLY (single session, produces a research digest) and FULL PIPELINE (3 sessions, produces a verified, peer-reviewed paper).

## Quick Install

### Option A: From GitHub (recommended)

```bash
# 1. Install the orchestrator skill via npx skills add
npx skills add <github-username>/academic-orchestrator -g -y

# 2. Install all dependency skills
bash ~/.claude/skills/academic-orchestrator/INSTALL.sh

# 3. Configure MCP servers in ~/.claude.json (see MCP Setup below)
#    Then restart Claude Code
```

### Option B: From local copy

```bash
cp -r academic-orchestrator ~/.claude/skills/
bash ~/.claude/skills/academic-orchestrator/INSTALL.sh
```

## Dependencies

### Skills (auto-installed by INSTALL.sh)
| Skill | Install Command | Required For |
|-------|----------------|-------------|
| deep-research | `anthropics/skills@deep-research` | Phase 2 web search |
| academic-researcher | `shubhamsaboo/awesome-llm-apps@academic-researcher` | Phase 3 writing |
| medical-imaging-review | (user custom, copy separately) | Phase 2/3 MEDICAL strategy |
| citation-management | `davila7/claude-code-templates@citation-management` | Phase 4 citations |
| latex-paper-en | `bahayonghang/academic-writing-skills@latex-paper-en` | Phase 5 LaTeX |
| fact-check | `jwynia/agent-skills@fact-check` | Phase 6 verification |
| peer-review | `poemswe/co-researcher@peer-review` | Phase 7 review |
| literature-review | `eyadsibai/ltk@literature-review` | Phase 1/3.2 methodology |
| academic-writing | `poemswe/co-researcher@academic-writing` | Phase 3.2 prose |
| writing-clearly-and-concisely | `obra/the-elements-of-style@writing-clearly-and-concisely` | Phase 8 polish |

### MCP Servers (manual configuration in ~/.claude.json)
| Server | Purpose | Config |
|--------|---------|--------|
| firecrawl | Web search + scraping | `mcpServers.firecrawl` (HTTP) |
| exa | Semantic web search | `mcpServers.exa` (HTTP) |
| semantic-scholar | Citation graph traversal | `mcpServers.semantic-scholar` (stdio: `aira-semanticscholar`) |

MCP config example in `~/.claude.json`:
```json
{
  "mcpServers": {
    "firecrawl": { "type": "http", "url": "https://mcp.firecrawl.dev/..." },
    "exa": { "type": "http", "url": "https://mcp.exa.ai/mcp?exaApiKey=..." },
    "semantic-scholar": {
      "type": "stdio",
      "command": "/opt/homebrew/bin/aira-semanticscholar",
      "args": [],
      "env": {}
    }
  }
}
```

## Usage

```
/academic-orchestrator
```

Or: "Use the academic orchestrator to research [topic]"

## File Structure

```
academic-orchestrator/
  SKILL.md       — The orchestrator (self-contained)
  README.md      — This file
  INSTALL.sh     — One-command dependency installer
```

## Migration

To move to another machine:
1. Copy this directory to `~/.claude/skills/academic-orchestrator/`
2. Run `bash INSTALL.sh`
3. Configure MCP servers in `~/.claude.json`
4. Restart Claude Code

## Sharing

To share with others:
1. Zip this directory: `zip -r academic-orchestrator-v5.2.0.zip academic-orchestrator/`
2. Share the zip + the MCP config example
3. Recipient unzips to `~/.claude/skills/`, runs INSTALL.sh, configures MCP

## Version History
- v5.2.0: Self-healing LaTeX compilation loop (max_retries=3)
- v5.1.0: Data & Licensing audit (Agent C in Phase 3.2)
- v5.0.0: Multi-pass writing (serial draft + parallel refinement ×3)
- v4.x: RESEARCH-ONLY path, multi-reviewer, adversarial verification
- v1-3: Initial architecture, context budget, session splitting
