#!/bin/bash
# Academic Orchestrator — Dependency Installer
# Run: bash INSTALL.sh
set -e

echo "=== Academic Orchestrator v5.2.0 — Installing Dependencies ==="
echo ""

# Core search skills
echo "[1/10] deep-research"
npx skills add anthropics/skills@deep-research -g -y 2>&1 | tail -1

echo "[2/10] academic-researcher"
npx skills add shubhamsaboo/awesome-llm-apps@academic-researcher -g -y 2>&1 | tail -1

echo "[3/10] literature-review"
npx skills add eyadsibai/ltk@literature-review -g -y 2>&1 | tail -1

# Writing skills
echo "[4/10] academic-writing"
npx skills add poemswe/co-researcher@academic-writing -g -y 2>&1 | tail -1

echo "[5/10] writing-clearly-and-concisely"
npx skills add obra/the-elements-of-style@writing-clearly-and-concisely -g -y 2>&1 | tail -1

# Formatting & citations
echo "[6/10] citation-management"
npx skills add davila7/claude-code-templates@citation-management -g -y 2>&1 | tail -1

echo "[7/10] latex-paper-en"
npx skills add bahayonghang/academic-writing-skills@latex-paper-en -g -y 2>&1 | tail -1

# Quality assurance
echo "[8/10] fact-check"
npx skills add jwynia/agent-skills@fact-check -g -y 2>&1 | tail -1

echo "[9/10] peer-review"
npx skills add poemswe/co-researcher@peer-review -g -y 2>&1 | tail -1

# MCP tool (requires npm)
echo "[10/10] semantic-scholar MCP"
npm install -g aira-semanticscholar 2>&1 | tail -1

echo ""
echo "=== Done. All dependencies installed. ==="
echo ""
echo "Next step: Configure MCP servers in ~/.claude.json"
echo "  - firecrawl (HTTP)"
echo "  - exa (HTTP)"
echo "  - semantic-scholar (stdio: aira-semanticscholar)"
echo ""
echo "Then restart Claude Code and try: /academic-orchestrator"
