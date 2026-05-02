# Phase 5: LaTeX Formatting (FULL strategy only)

## Input Convention
- Reads `phase3-draft.md` (or `phase3-draft-v1.md`)
- Reads `references.bib`
- Output: `manuscript.tex`, `manuscript.pdf`
- This phase is SKIPPED for Markdown-only output

---

## Phase 5: LaTeX Formatting with Self-Healing Compilation

### Step 5.1: Produce .tex File

If the draft is in Markdown:
1. Convert to LaTeX using the target venue's document class or a generic `article` class
2. Write to `manuscript.tex`
3. Ensure all `\cite{}` commands reference keys in `references.bib`

### Step 5.2: Self-Healing Compilation Loop

LaTeX code is brittle — unescaped special characters, missing `\usepackage`, or BibTeX mismatches cause fatal errors. A single diagnostic pass catches some issues, but the only proof of compilability is a successful `pdflatex` run. This step implements a **compile → diagnose → fix → recompile** loop with `max_retries = 3`.

**Loop algorithm:**

```
attempt = 0
while attempt < 3:
    1. Run compilation in Bash:
       pdflatex -interaction=nonstopmode manuscript.tex 2>&1 | tee /tmp/latex-output.log
       bibtex manuscript 2>&1 >> /tmp/latex-output.log
       pdflatex -interaction=nonstopmode manuscript.tex 2>&1 >> /tmp/latex-output.log
       pdflatex -interaction=nonstopmode manuscript.tex 2>&1 >> /tmp/latex-output.log

    2. Check exit code and log:
       if pdflatex returns 0 AND "Fatal error" NOT in log:
           → SUCCESS. Exit loop.
       else:
           attempt += 1
           if attempt == 3:
               → FAIL. Write the last error log to research-output/phase5-compile-errors.log.
                 Report to user: "LaTeX compilation failed after 3 attempts. 
                 Error log saved. Continue with Phase 6 on the last known-good draft?"
                 Do NOT block the pipeline — proceed to Phase 6 with the .md draft as fallback.

    3. Extract the FIRST fatal error from /tmp/latex-output.log:
       - grep for lines containing "! " (LaTeX error marker) or "Fatal error"
       - Extract the 5 lines before and after the error for context
       - Identify error type: undefined control sequence / missing package / 
         bad character escape / BibTeX mismatch / missing file

    4. Feed error to Agent for targeted fix:
       Launch a SINGLE Agent with the error context:
       "The LaTeX compilation failed with this error: [paste error block]. 
        Fix ONLY this specific error in manuscript.tex. Do NOT rewrite the document.
        Common fixes: escape underscores in non-math contexts, add missing \\usepackage{X}, 
        fix unbalanced braces, replace Unicode chars with LaTeX equivalents."

    5. Apply the Agent's fix to manuscript.tex
    6. Retry from step 1
```

**Why this works**: LaTeX errors are usually atomic — one bad `\usepackage`, one unescaped `_`, one mismatched brace. Fixing the first error often resolves cascading errors downstream. The loop targets one error per iteration, which is more reliable than trying to fix everything at once.

### Step 5.3: Final Diagnostic Pass

Once compilation succeeds, invoke `latex-paper-en` skill via the Skill tool for final polish:
- Structure check (abstract/conclusion alignment)
- Language polish (grammar, academic tone)
- Venue formatting compliance (if target specified)

Output: `manuscript.pdf` (compiled) + `manuscript.tex` (compilable source).

### Session 2 Checkpoint: Report to user (FULL strategy only). "LaTeX compilation: [SUCCESS after N attempts / FAILED — see phase5-compile-errors.log]. PDF generated: [yes/no]." For Markdown-only: skip Phase 5 entirely, proceed directly to /compact.

### END OF SESSION 2

**Before closing this session:**
1. Verify these files exist on disk: `manuscript.tex`, `references.bib`, `research-output/phase4-citation-report.md`
2. Tell the user: "Session 2 complete. `manuscript.tex` and `references.bib` are ready. Run `/academic-orchestrator` again and say 'continue from Phase 6' to start verification."
3. Run `/compact`

---

