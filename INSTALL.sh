#!/bin/bash
# Academic Orchestrator v6.3.0 — Dependency Installer
set -e

echo "=== Academic Orchestrator v6.3.0 — Installing Dependencies ==="

# MCP tools
echo "[1/5] arxiv-mcp-server"
pip3 install arxiv-mcp-server 2>&1 | tail -1

echo "[2/5] pubmed-mcp-server"
pip3 install pubmedmcp 2>&1 | tail -1

echo "[3/5] paper-search-mcp (Google Scholar, bioRxiv/medRxiv)"
pip3 install paper-search-mcp 2>&1 | tail -1

echo "[4/5] semantic-scholar MCP"
npm install -g aira-semanticscholar 2>&1 | tail -1

echo "[5/5] K-Dense-AI scientific skills (peer-review, paper-lookup, scholar-eval, critical-thinking)"
npx skills add K-Dense-AI/scientific-agent-skills -g -y 2>&1 | tail -3

echo ""
echo "=== Done. ==="
echo ""
echo "Optional MCP servers (configure in ~/.claude.json):"
echo "  - exa (HTTP): web search fallback"
echo "  - firecrawl (HTTP): web search + scraping"
echo "  - zotero (stdio): personal reference library"
echo ""
echo "Restart Claude Code and run: /academic-orchestrator"
