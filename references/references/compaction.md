## Context Management

The orchestrator cannot control when Claude Code auto-compacts. What it CAN do is ensure that compaction never loses work.

**What auto-compaction does and doesn't affect:**
- Compaction summarizes the CONVERSATION — it keeps a condensed version of the chat history. It does NOT touch files on disk.
- What's lost: the verbatim discussion thread, working memory of decisions, mid-task reasoning chain.
- What's safe: every file in `research-output/`. The draft. The merged report. The fact-check results. All on disk, all untouched.

**Three layers of protection against compaction loss:**
1. Every phase writes to disk before moving on. Even if compaction fires mid-sentence, the last checkpoint is saved.
2. Agent results are written to disk and cleared from working memory immediately — the largest context consumers (30-50K of raw search output) never stay in the conversation.
3. Large skills (analyzing-research-papers, peer-review) are never loaded in the main session via Skill tool. Their instructions go inline in Agent prompts instead.

**Progress markers for long operations**: Any operation processing >10 sequential items
MUST write a progress marker after each item. The marker doubles as the completion
record for that item — if the marker exists, the item is verified and on disk.

| Operation | Output File | Marker Format |
|-----------|------------|---------------|
| Phase 2 agent search | Individual agent .md files | Full file written = complete |
| Phase 6 fact-check | phase6-factcheck.md | `<!-- UNIT_N_OF_M_COMPLETE -->` after each section |
| Phase 7 peer review | Individual reviewer .md files | Full file written = complete |
| Phase 3 parallel refinement | Audit .md files | Full file written = complete |

**Recovery rule**: After compaction, re-read the output file. Items WITH markers are
done. Resume from the first item WITHOUT a marker. No reasoning-chain reconstruction needed.

**What to do when compaction fires:**

- **Between phases**: Ideal. Natural boundary. Files are complete with
  `<!-- PHASE_X_COMPLETE -->` markers. No context lost.

- **Mid-phase with progress markers**: Every long operation (>10 items: claims,
  references, sections) writes a progress marker after each item to its output file.
  After compaction, check the output file — items with completion markers are done.
  Resume from the first item WITHOUT a marker. The file IS the recovery state.

- **Mid-phase without progress markers** (short operations, <10 items): the operation
  is small enough to re-run from scratch. Re-read inputs and restart.

- Don't force `/compact`. When it fires, trust the markers.

**Soft guidance (not enforceable):**
- The pipeline is split across ~3 sessions because 8 phases typically won't fit in one. The actual split depends on when compaction fires.
- Token ranges below are typical estimates. Use as rough gauge, not constraint.

| Session | Phases | Typical Range | Main Contributors |
|---------|--------|--------------|-------------------|
| 1 | 1, 2, 2.4, 3 | 60-85K | Orchestrator (~13K) + 3 search agents (30-50K) + writing skill (~8K) + enriched draft (~6K) |
| 2 | 4, [+5 if LaTeX] | 15-35K | citation-management (~8K) + [latex-paper-en (~8K)] |
| 3 | 6, 7, 8 | 40-65K | fact-check (~11K) + manuscript (~5K) + 3 reviewers + elements-of-style (~2K) |

**Rules to stay within budget:**
- After each session: immediately run `/compact` to summarize before the next
- Never load a skill's SKILL.md unless actually invoking it in that session
- **Agent result disposal**: After writing agent results to files (Phase 2.2 and Phase 3.1b), do NOT keep raw agent output in working memory. Read only the merged/enriched files for subsequent phases
- Session 3: fact-check the manuscript section by section, don't load all at once
- **Skill-as-Agent pattern**: for tasks that would load a large skill (analyzing-research-papers, peer-review), use Agent tool with inline instructions instead of Skill tool. The skill's methodology goes into the agent prompt — the main session never loads the skill file
- Skill invocation costs (loaded in main session): orchestrator (13K), literature-review (4K), medical-imaging-review (8K), academic-writing (3K), citation-management (8K), fact-check (11K), latex-paper-en (8K), elements-of-style (2K)
- Skills NOT loaded in main session (used via Agent tool): analyzing-research-papers (4K would-be), peer-review (3K would-be)
- **MCP servers added to ~/.claude.json only take effect after restarting Claude Code.** If agents report a new MCP tool is unavailable, the user needs to restart. Agent prompts include PRIMARY/FALLBACK tool instructions so search quality degrades gracefully when MCP tools are not yet loaded

