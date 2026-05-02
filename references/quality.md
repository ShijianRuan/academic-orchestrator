## Anti-Patterns

| Don't | Because | Do Instead |
|-------|---------|------------|
| Ask agents to write files | Background agents often lack Write/Bash permissions | Agents return text inline; main session writes files |
| Combine Phase 3 + Phase 6 | Same pass can't reliably catch own hallucinations | Always separate generation and verification |
| Skip Phase 2 merge | Duplicate findings ≠ wasted effort; they're cross-validation | Merge and note agreement/disagreement |
| Run only one research skill | Single source type → blind spots | At minimum deep-research + academic-researcher |
| Skip human gates | User should confirm direction and review drafts | Always gate at Phase 1, Phase 3, Phase 5 |
| Let fact-check find errors → keep going | Errors compound | Fix all CONTRADICTED claims before Phase 7 |
| Launch agents sequentially | They'd run one at a time, defeating the purpose of parallel | Always put all Phase 2 Agent calls in ONE message |
| Use Skill tool for Phase 2 | Skill tool loads instructions into current context, not for delegation | Use Agent tool with tailored prompts for each perspective |

## Quality Heuristics

- **Source diversity**: Aim for ≥ 5 unique domains/hosts per research skill
- **Recency**: Prefer sources from last 3 years for fast-moving fields
- **Citation completeness**: Every factual claim traceable to a source
- **Unverified ceiling — contextual, not absolute**:
  - >15% unverified AND ≥2 are hard-number claims → confidence must be Low
  - >15% unverified but all are soft/inferential claims in a fast-moving field →
    confidence may remain Medium with explicit caveat stating which claims are unverified
  - The 15% is a HEURISTIC. The nature and consequence of unverified claims matters
    more than the count. A single unverified central thesis claim is more damaging than
    10 unverified peripheral observations.
- **Revision loop**: If peer review says Major Revision, loop once; if still Major, flag to user

