# Phase 3: Multi-Pass Draft Writing

## Input Convention
- `phase2-merged.md` structure: Agreements / Unique Findings / Contradictions / Source Inventory (with evidence levels [A/B/C/D] and DOIs)
- `phase3-field-structure.md` (produced by Round 1) structure: Method Categories / Field Evolution / Coverage Assessment / Proposed Paper Structure
- `phase3-deep-reads.md` (produced by Round 2, GATE 2 dependency)

---

## Phase 3: Multi-Pass Draft Writing (FULL pipeline only — not RESEARCH-ONLY)

Writing is inherently sequential at the structural level (you can't parallelize the act of composing a single narrative), but refinement passes on different dimensions CAN run in parallel. Phase 3 uses a **serial draft + parallel refinement + merge** pattern.

### Step 3.1: Round 1 — Structure Reads (before writing)

Deep reading happens in two rounds with different purposes and scopes. Round 1 happens BEFORE writing to inform structure. Round 2 happens DURING writing to fill in details.

#### Round 1 — Understand the Field Structure (before writing)

**Purpose**: Figure out how the field is organized — method categories, taxonomy, major trends — so you can design the paper's structure intelligently.

**What to read** (prioritize in this order):
1. **Recent surveys/reviews** (2024-2025) → these already organized the field for you. S2 MCP TLDRs and Phase 2 summaries quickly reveal which papers are surveys.
2. **Papers that propose taxonomies or classifications** → they tell you how the field divides itself.
3. **The most comprehensive paper from each apparent method category** → breadth over depth.

**Do NOT prioritize by citation count alone.** A 17K-citation paper may be a narrow technical breakthrough with no structural insight. A 50-citation survey may perfectly map the field.

**How many**: 5-8 papers. This is about understanding structure, not exhaustiveness.

**Process**:
1. From `phase2-merged.md`, identify papers flagged as surveys/reviews or taxonomies
2. Use S2 MCP TLDRs to quickly confirm: is this paper broad (covers the field) or narrow (covers one method)?
3. For the selected 5-8 papers, use Paper Search MCP (`get_paper_details`) + WebFetch to read Introduction, Related Work, and Method Classification sections
4. Record the field structure in `research-output/phase3-field-structure.md`:
   - Method categories (what are the main families?)
   - How the field evolved (timeline of key milestones)
   - Which sub-topics are well-covered vs under-explored
   - Proposed paper section structure
5. This feeds directly into Step 3.2 (Structural Draft) — the writing skill now knows how to organize the paper

#### Round 2 — Fill in Precise Details (during writing)

**Purpose**: After the structural draft exists (Step 3.2), fill in exact numbers, method specifics, and author-stated caveats that Phase 2 summaries may have omitted or approximated. This step is MANDATORY — see enforcement below.

**Every paper already has** (from Phase 2 + S2 MCP):
- Phase 2 summary (1-2 sentences) + S2 MCP TLDR + Citation count + Evidence level [A/B/C/D] + DOI/URL

**Deep-read a paper only when the draft NEEDS it:**

| Trigger | Example |
|---------|---------|
| Draft needs an exact number | "achieves Dice 0.XXX" → verify the actual value |
| Writing Methods → need architecture specifics | Batch size, optimizer — never in summaries |
| Writing Results comparison → need benchmark numbers | Summaries may round or approximate |
| Paper cited by 3+ others in the survey | Field anchor — its claims affect everything |
| Draft has a gap in a sub-topic | Deep-read the best paper covering it |
| Discussion needs author-stated limitations | Only the original paper honest states its weaknesses |

**What NOT to deep-read**: [C][D] papers, papers cited once in passing, papers confirming what others already say.

**How many**: No fixed number. The draft drives selection — more gaps mean more deep-reads, fewer gaps mean fewer. The decision belongs to the writer, but the decision PROCESS is mandatory (see Step 3.3b below). Context strategy: launch deep-read agents with `run_in_background: true` + write to `phase3-deep-reads.md` + dispose raw output (same as Phase 2 agent pattern). Main session reads only the compiled file.

**Process**:

#### Step 3.3a: Assess Draft Needs
1. Review the structural draft systematically. For each section, identify gaps:
   - Approximate numbers needing exact verification
   - Thin method descriptions (missing architecture, training, evaluation details)
   - Missing benchmark comparisons (no specific Dice/HD95 values)
   - Limitations relying on summaries rather than author-stated caveats
2. List papers that need deep-reading and what specific information is needed from each

#### Step 3.3b: Execute (or Document No-Op)
1. Launch 2 agents in parallel (background + file output + disposal):
   - Paper Search MCP + S2 MCP + WebFetch → extract exact metrics, methods, limitations, quotes
2. Write `research-output/phase3-deep-reads.md`
3. Enrich the draft from this file: fill numbers, add method specifics, insert caveats

#### Step 3.3c: Required Output (GATE 2 dependency)

`research-output/phase3-deep-reads.md` MUST contain EITHER:

**(A) Deep-read findings** — per paper: exact numbers verified, method details extracted, author-stated limitations, quotes. Then enrich the draft.

**(B) Documented no-op assessment** — if the draft genuinely has sufficient detail from Phase 2 summaries. Generic claims like "Phase 2 was sufficient" are NOT acceptable. The assessment MUST complete this structured checklist with specific Phase 2 evidence for each category:

```
□ Exact numbers: [cite the specific Phase 2 finding that provides the exact value needed]
□ Architecture specifics (batch size, optimizer, loss function): [cite specific finding, or state "not applicable to this survey's scope"]
□ Benchmark comparison numbers: [cite specific Phase 2 Dice/HD95 values for each benchmark]
□ Author-stated limitations: [quote or paraphrase the specific limitation from the Phase 2 summary]
□ Field-anchor paper verification (papers cited ≥3 times): [cite per-paper verification from Phase 2]
```

If ANY category is answered with a generic statement rather than a specific Phase 2 citation, the assessment is INSUFFICIENT and Round 2 deep-reads MUST be executed for that category.

**GATE 2 review power**: If the orchestrator judges the no-op assessment insufficient (generic claims without specific Phase 2 evidence), GATE 2 MUST reject it and require Round 2 execution before proceeding.

**GATE 2 dependency**: Before GATE 2, verify `phase3-deep-reads.md` exists. If missing → gate blocked. Gate summary must include: "Round 2: [N] papers deep-read, [M] exact numbers verified, [K] gaps covered by Phase 2".

### Step 3.2: Structural Draft (Write with Structure Knowledge)

Invoke the primary writing skill via the Skill tool:
- MEDICAL strategy → `medical-imaging-review`
- ACADEMIC or GENERAL strategy → `academic-researcher`

Provide as context: `research-output/phase2-merged.md` + `research-output/phase3-field-structure.md`. Output to `research-output/phase3-draft-v1.md`.

**CRITICAL — Citation accuracy**: Every [N] in the draft MUST map to the correct source in phase2-merged.md Source Inventory. Before writing a claim, verify: (1) does the cited paper actually say this? (2) is [N] the correct entry for this paper? Misattributing a claim to the wrong reference number is the most common and most damaging error. Cross-check each citation against the Source Inventory before finalizing the draft.

### Step 3.4: Parallel Refinement (3 Agents, Background)

Launch 3 Agent tasks IN A SINGLE MESSAGE with `run_in_background: true`. Each refines the draft on a different, independent dimension:

```
Agent A — Prose Quality (academic-writing perspective):
  prompt: |
    Read the draft below. Focus ONLY on language quality:
    - Remove hedging soup (every paragraph ≤2 hedging words: potentially, may, might, could, arguably, perhaps)
    - Replace formulaic transitions (Furthermore, Moreover, Additionally, It is important to note that) with logical flow
    - Strengthen specificity: replace abstract claims with named studies, sample sizes, years
    - Inject authorial voice where the discipline permits
    - Do NOT change structure, facts, citations, or argument. Only language.
    Return the refined prose inline as text.

Agent B — Citation Completeness (literature-review perspective):
  prompt: |
    Read the draft below. Focus ONLY on citation coverage:
    - Are all factual claims backed by a citation?
    - Are there missing seminal works that should be cited?
    - Are any citations attributed to the wrong paper?
    - Check against the merged research notes (phase2-merged.md) for cited-but-not-in-sources
    Return a checklist: [MISSING] for missing citations, [WRONG] for misattributed, [OK] for correct.
    Reference claims by their SEMANTIC CONTENT (e.g., "claim: TotalSegmentator Dice 0.943"),
    NOT by line numbers or exact sentence text. This ensures fixes can be applied after prose refinement.
    Do NOT rewrite prose. Just return the citation audit.

Agent C — Data & Licensing Audit (medical-imaging domain focus):
  prompt: |
    Read the draft below. Focus ONLY on dataset provenance and licensing:
    For EVERY dataset mentioned in the draft, extract and verify:
    - **Dataset name and source repository** (e.g., TCIA collection ID, Zenodo DOI, GitHub release)
    - **Coverage / FOV**: anatomical regions covered, organs included, any notable exclusions
    - **License type**: CC BY 3.0, CC BY 4.0, CC BY-NC (non-commercial only), custom/proprietary, or unspecified
    - **Commercial use**: explicitly permitted, restricted, or unclear from the license
    - **Key caveats**: pediatric patients excluded? pathology cases excluded? single-vendor only?
    
    Return a structured audit. For each dataset:
    ```
    ### [Dataset Name]
    - **Source**: [URL / DOI / TCIA ID]
    - **Coverage**: [FOV description]
    - **License**: [CC BY 3.0 / CC BY 4.0 / CC BY-NC / Proprietary / Unspecified]
    - **Commercial use**: [Permitted / Restricted / Unclear]
    - **Caveats**: [any limitations on scope, population, or vendor]
    ```
    
    Also flag any dataset mentioned WITHOUT an explicit citation or source link → [UNVERIFIED-DATASET].
    Reference datasets by their NAME (e.g., "dataset: AMOS"), NOT by line numbers.
    This ensures fixes can be applied after prose refinement.
    Do NOT rewrite prose. Just return the data audit.

**Scope note**: This audit verifies DATASET licenses and provenance only. It does NOT check:
- **Model weight licenses** — VISTA3D's MONAI/NIM terms, Merlin's weight availability, SegVol's release terms. These are covered by the Code Repository Audit (Step 3.6) when the user requests it.
- **Tool/dependency licenses** — MONAI, PyTorch, nnU-Net framework, NVIDIA NIM. These are infrastructure concerns, not survey content.
- **Training data provenance beyond what the paper discloses** — if a paper says "trained on 90K CT volumes" without listing sources, the audit cannot verify origins.

If model weight licenses or commercial deployment terms matter for your survey, trigger the Code Repository Audit (Step 3.6) for the relevant papers.
```

### Step 3.5: Merge Refinements

**Why parallel works**: Prose, citations, and data licensing are three orthogonal dimensions.
Agents B and C return checklists (not rewritten prose), so no prose-level merge conflicts exist.
All 3 agents run in parallel on the same v1 draft for wall-clock speed.

**Merge order** (sequential application, parallel execution):

When all 3 agents complete:
1. **Apply Agent A's prose refinements** to v1 → `phase3-draft-v2.md`
   (A returns full rewritten prose — this is canonical)
2. **Apply Agent B's citation fixes** to v2 → `phase3-draft-v3.md`:
   - For each [MISSING]/[WRONG], locate the semantically closest sentence in v2
     (Agent A's prose changes may have moved or reworded target sentences)
   - If a fix cannot be applied because the target claim no longer exists:
     mark it [UNAPPLIED: reason] in the audit file — do NOT silently drop
3. **Apply Agent C's data notes** to v3 → `phase3-draft.md` (final):
   - Add license/caveat annotations to dataset descriptions
   - Flag [UNVERIFIED-DATASET] items as caveats in the text
   - Same semantic-location rule as B: find by dataset name, not line number
4. Record audits: `research-output/phase3-citation-audit.md` (Agent B),
   `research-output/phase3-data-licensing-audit.md` (Agent C)
5. **Clear raw agent output from working memory after writing files**

**Conflict resolution priority**: Prose (A) > Citations (B) > Data (C).
Prose is canonical — citations and data are annotations on the prose.
If a citation or data fix cannot be cleanly applied, record it as [UNAPPLIED]
rather than forcing it into the wrong location.

### Draft Quality Minimums
- Topic sentences with clear claims
- Every factual claim has at least an inline citation marker
- Method descriptions include limitations
- Comparison table for each major section (if ≥ 3 items to compare)
- **Survey Methodology subsection**: State search period, databases/sources used, keywords, inclusion/exclusion criteria, and the multi-source cross-validation approach
- **Citation audit passed**: All [MISSING] and [WRONG] items from Step 3.2 Agent B resolved
- **Data & licensing audit passed**: All datasets have verified sources and license annotations; [UNVERIFIED-DATASET] items flagged as caveats in the text. Note: this audit covers dataset licenses only. Model weight/tool licenses → see Code Repository Audit (Step 3.6)

### Step 3.6: Code Repository Audit (OPTIONAL)

**Trigger**: Run when the user shows ANY intent to go beyond reading the paper: code access, implementation details, reproduction, testing, training requirements, GPU specs, pretrained weights, licensing. Example: "I want to try this", "can I run this", "what GPU", "is the code available", "how do I train this", "any pretrained weights".

**No dedicated MCP or skill exists for this purpose.** The ecosystem has repo-scan (1.7K installs) but it scans LOCAL codebases (C++/Java/iOS), not remote paper repos. Use built-in tools:

| Need | Tool | How |
|------|------|-----|
| Find paper's GitHub repo | `gh search repos "[paper title]" --limit 5` | Bash |
| | or WebSearch "[paper title] github" | WebSearch |
| Read README | WebFetch `https://raw.githubusercontent.com/.../README.md` | WebFetch |
| Read training config | WebFetch `configs/*.yaml` or `*.json` (in repo) | WebFetch |
| Read dependencies | WebFetch `requirements.txt` or `environment.yml` | WebFetch |
| Check for pretrained weights | WebSearch `[model name] pretrained weights download` | WebSearch |
| Check inference demo | WebFetch repo tree → look for `demo.py`, `inference.py`, `predict.py`, Colab link | WebFetch |

**REPO VERIFICATION — do this first, before auditing:**

1. `gh search repos "[paper title]" --limit 5` → get candidate URLs
2. For each candidate, WebFetch its README. Verify AT LEAST 2 of: README mentions paper title/DOI, repo owner matches paper first author or lab, README describes the paper's method, repo has ≥10 stars or recent commits
3. No candidate passes → mark "[NOT FOUND — no verified public repo]"
4. Candidate passes → confirm with second file check (requirements.txt or setup.py exists)

**8-POINT AUDIT — only on verified repos:**

```
□ Official repo URL: [verified github.com/...] or "[NOT FOUND — no verified public repo]"
□ Pretrained weights: [URL] or "[NOT FOUND]" or "[in repo — download script]"
□ GPU requirement: [X GB VRAM / "not stated"] — search README + configs for "GPU", "memory", "batch"
□ Training specifics: [unique loss / custom scheduler / gradient clip value / mixed precision] — from train config
□ Inference demo: [filename] or "[NOT FOUND — no demo script]"
□ Dependency pinning: [pinned / unpinned] — check requirements.txt for == vs >=
□ Data preprocessing: [script exists / documented only / not provided]
□ License: [MIT / Apache / CC BY-NC / custom / not stated]
```

Save to `research-output/phase3-code-audit.md`. Add key findings (GPU requirements, license restrictions, pretrained weight availability) as implementation notes in the draft.

**Why top-3 only**: Auditing 3 repos involves 10-15 WebFetch calls. More than that adds significant context pressure and wall-clock time with diminishing returns — the top papers' repos cover the core implementation patterns.

### Step 3.7: Figure & Table Extraction from Papers (OPTIONAL)

**When to invoke** (decision matrix):

| Scenario | Invoke? | Reason |
|----------|---------|--------|
| Writing survey, need method architecture comparison | ✅ | Figures show architecture differences visually |
| Writing Methods/Related Work section, need to describe a pipeline | ✅ | Flowcharts and schematics are the most valuable figures to extract |
| Draft references a specific figure or needs a method's workflow explained | ✅ | Schematic extraction saves the reader from flipping to the original paper |
| Need exact performance numbers from a paper's results table | ✅ | Paper tables have precise metrics the summary may have rounded |
| User asks "show me Figure X" or "what does this architecture look like" | ✅ | Direct user request |
| RESEARCH-ONLY digest | ❌ | Phase 2 summaries are sufficient |
| Paper has no HTML version (PDF-only) | ❌ | `read_arxiv_paper` extracts text only — figures inaccessible without PDF tools (pdfplumber/PyMuPDF, too heavy) |
| User just wants a quick overview | ❌ | Skip; offer if user later asks for details |

**How to extract** (no external skill needed — built-in tools):

1. **For arXiv papers**: WebFetch `https://arxiv.org/html/[paperID]` — the HTML version renders figures inline with captions. Search the page for `<figure>`, `<img>`, `<figcaption>` tags.
2. **For PMC papers**: WebFetch the PMC HTML page. Similar structure — figures and tables are embedded.
3. **For publisher HTML pages**: WebFetch the paper URL. Extract `<img>` tags with alt text and surrounding caption paragraphs.

**What to extract** (record in `research-output/phase3-figures.md`):
- Figure number + caption text
- Figure type: [architecture diagram / flowchart / schematic / pipeline / results chart / table]
- Image URL (if accessible)
- Key takeaway (1 sentence — what does the figure show or prove?)
- For tables: the full table data, preserving rows and columns

**Usage in the draft**:
- **Architecture diagrams & flowcharts**: When writing a Methods or Related Work section, describe the method's architecture while referencing the extracted figure. Example: "[Author]'s pipeline (Fig. 2) consists of three stages: encoder → diffusion bridge → decoder." This gives the reader visual context without needing to flip to the original paper.
- **Schematics & pipelines**: Use extracted pipeline diagrams to compare workflows across methods. Describe them side-by-side in your draft.
- **Results charts & tables**: Cite extracted performance data in comparison tables. Reference the original figure for visual confirmation.
- Important: describe and reference, do NOT embed the original image in your manuscript — that's copyright infringement unless it's CC BY licensed.

**Why not use `figure-generation` skill?** It has a failed security audit (Gen Agent Trust Hub: FAIL) and 137 installs. Claude can write matplotlib code directly if a new figure is needed — no skill required.

### GATE 2: Present the draft summary to the user. "Draft complete — [N] words, [M] sources. Round 2: [N] papers deep-read, [M] exact numbers verified, [K] gaps covered by Phase 2. Citation audit: [N] missing, [M] misattributed (all fixed). Review before verification?" Do NOT proceed until the user confirms. If `phase3-deep-reads.md` does not exist, GATE 2 MUST NOT be presented — go back to Step 3.3.

