# Phase 4: Citation Management + Source Quality

## Input Convention
- Reads `phase3-draft.md` (inline citation markers [N] + References section)
- Reads `phase2-merged.md` (source inventory with DOIs — for existence verification)
- Output: `references.bib`, `phase4-citation-report.md`

---

## Phase 4: Citation Management + Source Quality

Invoke `citation-management` skill via the **Skill tool**.

Input: The inline citation markers and source inventory from `phase3-draft.md`.

The skill handles:
- DOI/PMID/arXiv ID → full metadata resolution
- Metadata cross-referencing (CrossRef vs PubMed vs arXiv)
- Duplicate detection
- Required field completeness checking
- BibTeX generation and formatting

**Orchestrator-specific additions** (execute after the skill's core tasks):

1. **Reference existence verification**: For EVERY reference WITHOUT a verified DOI:
   - Use `mcp__semantic-scholar__search-paper-title` with the paper's title
   - If found: verify author names, year, and venue match. If metadata differs → correct it.
   - If NOT found: flag as `[VERIFICATION-FAILED: paper not found in Semantic Scholar]`

2. **Retraction check**: For the top-10 most-cited or most-critical sources:
   - WebFetch `https://pubmed.ncbi.nlm.nih.gov/?term=[paper title] retraction`
   - Flag any retracted papers in the citation report

3. **Preprint → published upgrade**: For arXiv preprints, check if a peer-reviewed journal version exists (via Semantic Scholar MCP). If yes → use the published version.

4. **Source quality annotation**: Extend the evidence ladder from Phase 2.3 into the citation report. Mark each reference with its evidence level [A/B/C/D].

Output:
- `references.bib` — cleaned, validated BibTeX file
- `research-output/phase4-citation-report.md` — issues found, retraction status, evidence levels, existence verification results

### Step 4.3: Verification (severity-graded validation report)

After citation-management generates `references.bib`, run multi-dimensional validation and produce a severity-graded report. This catches errors that the skill's internal checks may miss.

1. **Run multi-dimensional duplicate detection**:
   - DOI matching (exact string comparison on normalized DOIs)
   - Title similarity (case-insensitive, after stripping punctuation; flag pairs with >80% overlap)
   - Same author surname + year + title keyword combinations
   - Record duplicates found and which entry was kept

2. **Run field completeness check** on every BibTeX entry:
   - Required fields present: author, title, year, venue (journal/booktitle), DOI or URL
   - Missing DOI: flag as WARNING (not ERROR — some papers genuinely lack DOIs)
   - Missing year: flag as ERROR
   - Missing author: flag as ERROR

3. **Cross-check against Source Inventory**: For every entry in references.bib, verify a corresponding row exists in phase2-merged.md Source Inventory (by DOI or title match). Entries in .bib without inventory match → flag as WARNING (may be legitimate post-Phase-2 additions from citation chaining).

4. **Write `research-output/phase4-validation.md`**:

```markdown
# Citation Validation Report: [Topic]
*Generated: [date]*

## Summary
| Severity | Count | Description |
|----------|-------|-------------|
| ERROR | N | Must fix before GATE 3 |
| WARNING | M | Review before GATE 3 |
| INFO | K | No action required |

## ERROR Items
| # | Entry | Issue | Fix |
|---|-------|-------|-----|
| 1 | [cite key] | Missing author field | Add from DOI metadata |
| 2 | [cite key] | Duplicate of [other key] | Merge, keep [key] |

## WARNING Items
| # | Entry | Issue | Recommendation |
|---|-------|-------|----------------|
| 1 | [cite key] | Missing DOI | Verify paper exists via title search |
| 2 | [cite key] | No Source Inventory match | Add to inventory or flag as post-Phase-2 addition |

## INFO Items
| # | Entry | Note |
|---|-------|------|
| 1 | [cite key] | Preprint — check for published version |

## Duplicates Detected
| Keep | Remove | Match Type | Confidence |
|------|--------|------------|------------|
| [key A] | [key B] | DOI exact match | HIGH |

## Field Completeness
- Total entries: N
- Complete (all required fields): N
- Missing DOI: N
- Missing year: N
- Missing author: N
```

5. **Severity thresholds**:
   - ERROR count > 0 → fix all before GATE 3
   - WARNING count > 5 → review and address before GATE 3
   - INFO items → document, no action required

6. This file is a **GATE 3 Layer 1 dependency** (validated by `check G3-F3` in validate.sh).

---

