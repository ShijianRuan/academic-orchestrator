#!/bin/bash
# Academic Orchestrator v6.3.0 — Dependency Installer
set -e

SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_SKILLS="$HOME/.claude/skills"

echo "=== Academic Orchestrator v6.3.0 — Installing Dependencies ==="

# 1. Copy bundled skills
echo "[1/2] Installing bundled skills..."
for skill in deep-research academic-researcher medical-imaging-review citation-management fact-check peer-review literature-review writing-clearly-and-concisely latex-paper-en paper-lookup scientific-critical-thinking scholar-evaluation; do
    if [ -d "$SKILL_DIR/skills/$skill" ] && [ ! -d "$CLAUDE_SKILLS/$skill" ]; then
        cp -r "$SKILL_DIR/skills/$skill" "$CLAUDE_SKILLS/$skill"
        echo "  + $skill"
    elif [ -d "$CLAUDE_SKILLS/$skill" ]; then
        echo "  · $skill (already installed)"
    else
        echo "  ! $skill (not found in bundle)"
    fi
done

# 2. Install MCP tools
echo ""
echo "[2/2] Installing MCP tools..."

echo "  - arxiv-mcp-server"
pip3 install arxiv-mcp-server 2>&1 | tail -1

echo "  - pubmed-mcp-server"
pip3 install pubmedmcp 2>&1 | tail -1

echo "  - paper-search-mcp (Google Scholar, bioRxiv/medRxiv)"
pip3 install paper-search-mcp 2>&1 | tail -1

echo "  - semantic-scholar MCP"
npm install -g aira-semanticscholar 2>&1 | tail -1

echo ""
echo "=== Done. ==="
echo ""
echo "Optional MCP servers (configure in ~/.claude.json):"
echo "  - exa (HTTP): web search"
echo "  - firecrawl (HTTP): web scraping"
echo "  - zotero (stdio): personal reference library"
echo ""
echo "Restart Claude Code and run: /academic-orchestrator"
