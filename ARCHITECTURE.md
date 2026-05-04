# Academic Orchestrator v6.3.0 — Architecture

```
══════════════════════════════════════════════════════════════════════
                        RESEARCH-ONLY PATH
                      (Single Session, ~40K tokens)
══════════════════════════════════════════════════════════════════════

  Phase 1          Phase 2                    Phase R
  ┌──────────┐    ┌─────────────────────┐    ┌──────────────────┐
  │ 需求分析  │───→│ 三路并行搜索          │───→│ 格式自适应摘要     │
  │ 领域路由  │    │                      │    │                  │
  │          │    │ deep-research ─┐     │    │ 对比表 / 时间线   │
  │ [门禁 1] │    │ academic-researcher ─┤ │    │ 分类列表 / 建议   │
  └──────────┘    │ medical-imaging ─┘   │    │ 交叉验证矩阵      │
                  │       ↓              │    │ 语言润色          │
                  │  合并 + 交叉验证      │    │                  │
                  │  引文追溯 (S2 MCP)   │    │ [门禁 R]         │
                  └─────────────────────┘    └──────────────────┘
                                                     ↓
                                          research-digest.md (单文件)


══════════════════════════════════════════════════════════════════════
                         FULL PIPELINE
                     (3 Sessions, ~150K tokens total)
══════════════════════════════════════════════════════════════════════

SESSION 1 ── 研究 + 写作 (~60K)
─────────────────────────────────
  Phase 1 → Phase 2 → Phase 3

  Phase 2: 四路并行搜索 (Agent x4, bg)
  ┌───────────────────────────────────────────┐
  │ deep-research  academic-researcher        │
  │ medical-imaging  paper-lookup             │
  │              ↓                            │
  │   PRISMA 筛选 + 交叉验证 + 引文追溯 (S2)   │
  └───────────────────────────────────────────┘

  Phase 3: 多轮写作
  ┌─────────────────────────────────────────┐
  │ 3.1 结构阅读 → 3.2 Skill 写结构稿         │
  │          ↓                              │
  │ 3.3 深度阅读注入 (MANDATORY)              │
  │          ↓                              │
  │ 3.4 三路并行精炼                          │
  │   ┌──────────┬──────────┬─────────────┐ │
  │   │ 文笔强化  │ 引用审计  │ 数据合规审计  │ │
  │   └──────────┴──────────┴─────────────┘ │
  │          ↓                              │
  │ 3.5 合并修订 → 终稿                       │
  └─────────────────────────────────────────┘
                    ↓
              [门禁 2] → /compact


SESSION 2 ── 引用 + 排版 (~25K)
─────────────────────────────────
  Phase 4 → Phase 5

  Phase 4: 引用管理 + 验证
  ┌─────────────────────────────────┐
  │ Skill(citation-management)      │
  │   + 撤稿检查 + 预印本升级         │
  │   + Step 4.3 严重度分级验证报告   │
  │ → references.bib                │
  └─────────────────────────────────┘

  Phase 5: LaTeX 自愈编译
  ┌─────────────────────────────────┐
  │  pdflatex → 失败?               │
  │    ├─ 提取错误 → Agent 修复      │
  │    └─ 重试 (max 3)              │
  │  → manuscript.pdf (可编译)       │
  └─────────────────────────────────┘
                    ↓
              /compact


SESSION 3 ── 验证 + 审稿 + 终稿 (~50K)
───────────────────────────────────────
  Phase 6 → Phase 7 → Phase 8

  Phase 6: 事实核查 + 对抗验证
  ┌─────────────────────────────────┐
  │ Skill(fact-check) ← 独立 pass   │
  │ 逐条声明 vs 来源                 │
  │ 对抗搜索 → 对 HIGH 声明找反证    │
  │ Step 6.4.5: 证据等级审计         │
  │ 修正 → 写盘                      │
  └─────────────────────────────────┘
              ↓
         [门禁 3]

  Phase 7: 四人并行审稿
  ┌──────────┬──────────┬──────────┬──────────┐
  │ 审稿人 A  │ 审稿人 B  │ 审稿人 C  │ 审稿人 D  │
  │ 方法学家  │ 领域专家  │ 通才编辑  │ K-Dense  │
  └──────────┴──────────┴──────────┴──────────┘
              ↓
           Phase 7.5: ScholarEval 量化评分
              ↓
         合并共识 (2+同意 → 必改)
              ↓
         [门禁 4]

  Phase 8: 终稿
  ┌─────────────────────────────────┐
  │ 引用终验 → 语言润色 → 交付包     │
  └─────────────────────────────────┘
              ↓
         [门禁 5] → manuscript.pdf


══════════════════════════════════════════════════════════════════════
                         MCP 工具策略 (v6.3)
══════════════════════════════════════════════════════════════════════

  设计原则：Skill 定义工具，Orchestrator 不覆盖

  ┌──────────────────────────────────────────────────────────────┐
  │ Agent            │ 工具来源          │ 主工具               │
  ├──────────────────┼──────────────────┼──────────────────────┤
  │ deep-research    │ skill SKILL.md   │ Exa + Firecrawl      │
  │ academic-researcher│ orchestrator prompt│ S2+arXiv+PubMed+Scholar │
  │ medical-imaging  │ skill allowed-tools│ arxiv+pubmed+zotero │
  │ paper-lookup     │ orchestrator prompt│ 10-database REST    │
  └──────────────────────────────────────────────────────────────┘

  WebSearch (Claude Code 内置):
  - ❌ DeepSeek API: v2.1.126 deferred tools 重构后不可用
  - ✅ Anthropic 原生 API: 正常
  - 替代方案: Exa MCP (mcp__exa__web_search_exa)

  Tool Choice Matrix:
  ┌────────────────────────┬──────────────────┬──────────────────┐
  │ 用途                   │ 主工具            │ 备选             │
  ├────────────────────────┼──────────────────┼──────────────────┤
  │ arXiv 搜索             │ arxiv-mcp-server │ S2 (覆盖所有 arXiv)│
  │ PubMed 搜索            │ pubmed-mcp-server│ paper-search PubMed│
  │ Google Scholar         │ paper-search     │ 无替代             │
  │ 通用网页搜索           │ Exa MCP          │ Firecrawl (配额)  │
  │ 语义学术搜索           │ Semantic Scholar │ Exa web search    │
  └────────────────────────┴──────────────────┴──────────────────┘


══════════════════════════════════════════════════════════════════════
                      质量保障层
══════════════════════════════════════════════════════════════════════

  ┌──────────────┬──────────────┬──────────────┬──────────────┐
  │  搜索质量     │  写作质量     │  验证质量     │  排版质量     │
  ├──────────────┼──────────────┼──────────────┼──────────────┤
  │ 四源并行      │ 领域结构模板   │ 独立事实核查   │ 自愈编译循环   │
  │ 交叉验证      │ 三路并行精炼   │ 对抗反证搜索   │ max_retries=3 │
  │ 引文追溯(S2)  │ 深度阅读注入   │ 证据等级审计   │ 投稿格式诊断   │
  │ 证据分级[A-D] │ 引用完整性审计 │ 四人并行审稿   │              │
  │ PRISMA框架   │ 数据合规审计   │ ScholarEval    │              │
  └──────────────┴──────────────┴──────────────┴──────────────┘


══════════════════════════════════════════════════════════════════════
                      Skill 调用矩阵
══════════════════════════════════════════════════════════════════════

  阶段  Skill                           调用方式
  ──── ───────────────────────────────  ──────────────────
   1   (Agent) + literature-review      AskUserQuestion + Skill
   2   4 Agent 并行 + PRISMA + 引文追溯   Agent (bg) x4
   3   medical-imaging-review + 3 精炼   Skill + Agent (bg) x3
   4   citation-management + 验证报告    Skill + orchestrator additions
   5   latex-paper-en + 自愈编译        Skill + Bash
   6   fact-check + 对抗验证 + 等级审计  Skill + orchestrator additions
   7   4 Agent 并行审稿 + ScholarEval   Agent (bg) x4 + Skill
   8   引用终验 + Elements of Style     Skill + Agent (bg)

  Skill 文件部署:
  所有引用 skill 的 SKILL.md 及 references/ 均已复制到 skills/ 目录下：
  - skills/deep-research/
  - skills/academic-researcher/
  - skills/medical-imaging-review/
  - skills/citation-management/
  - skills/fact-check/
  - skills/peer-review/
  - skills/literature-review/
  - skills/writing-clearly-and-concisely/

## 两条路径

| 路径 | 阶段数 | Session | 产出 | 适合 |
|------|--------|---------|------|------|
| RESEARCH-ONLY | 3 (1→2→R) | 1 | 研究摘要 (单文件) | 快速调研、数据收集 |
| FULL PIPELINE | 8 (1→8) | 3 | 论文 PDF + 验证报告 | 正式论文、综述 |

## 兼容性说明

| 模型 | WebSearch | MCP 工具 | 状态 |
|------|-----------|---------|------|
| Anthropic (Claude) | ✅ | ✅ | 全功能 |
| DeepSeek (v4-pro) | ❌ | ✅ | WebSearch 需用 Exa 替代 |

## 安装

```bash
npx skills add ShijianRuan/academic-orchestrator -g -y
bash ~/.claude/skills/academic-orchestrator/INSTALL.sh
```
