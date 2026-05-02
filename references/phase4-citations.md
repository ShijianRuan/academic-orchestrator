# Phase 4: Citation Management + Source Quality

## Input Convention
- Reads `phase3-draft.md` (inline citation markers [N] + References section)
- Reads `phase2-merged.md` (source inventory with DOIs — read on demand, not loaded upfront)
- Output: `references.bib`, `phase4-citation-report.md`

---

## Phase 4: Citation Management + Source Quality

Invoke `citation-management` skill via the Skill tool.

Input: The inline citation markers and source inventory from `research-output/phase3-draft.md`.

Tasks:
1. For each source, resolve DOI/PMID/arXiv ID → full metadata
2. Generate `references.bib` with all entries validated
3. Check for: missing required fields, duplicate entries, broken DOIs
4. Format BibTeX consistently (standardize field order, author names, capitalization)

**Additional quality checks (performed by the main agent, not citation-management):**
5. **Retraction check**: For the top-10 most-cited or most-critical sources, WebFetch `https://pubmed.ncbi.nlm.nih.gov/?term=[paper title] retraction` or similar. Flag any retracted papers in the citation report
6. **Preprint → published upgrade**: For arXiv preprints, check if a peer-reviewed journal version exists (via Semantic Scholar MCP or CrossRef). If yes → use the published version
7. **Source quality annotation**: Extend the evidence ladder from Phase 2.3 into the citation report. Mark each reference with its evidence level [A/B/C/D]

Output:
- `references.bib` — cleaned, validated BibTeX file
- `research-output/phase4-citation-report.md` — issues found, retraction status, evidence levels

---

