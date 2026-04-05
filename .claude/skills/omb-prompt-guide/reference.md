# Prompt Engineering Reference — Deep Dive

## Table of Contents

1. [Research-Backed Principles](#1-research-backed-principles) — Prompt repetition, multi-turn degradation, lost in the middle, example order sensitivity
2. [Technique Catalog](#2-technique-catalog) — T1-T15: execution structure, output contracts, completion criteria, beautiful defaults, litmus checks, and more
3. [Model-Specific Notes](#3-model-specific-notes) — Claude, GPT, Gemini patterns and routing
4. [Agentic System Patterns](#4-agentic-system-patterns) — State tracking, autonomy, orchestration
5. [Prompt Quality Checklist](#5-prompt-quality-checklist) — Universal review checklist
6. [CSO Doctrine Reference](#6-cso-doctrine-reference) — Skill description writing
7. [Templates](#7-templates) — Agent, output contract, workflow templates
8. [Skill Prompt Writing Guide](#8-skill-prompt-writing-guide) — Three-level loading, description optimization, body writing
9. [Agent Prompt Frontmatter Reference](#9-agent-prompt-frontmatter-reference) — `.claude/agents/omb/*.md` schema and patterns

Companion document to `SKILL.md`. Contains research citations, technique catalog, model-specific notes, and templates.

---

## 1. Research-Backed Principles

### Prompt Repetition (Google Research, December 2025)

**Paper:** "Prompt Repetition Improves Non-Reasoning LLMs"

**Finding:** Duplicating the prompt query (`<QUERY>` → `<QUERY><QUERY>`) improved performance in 47 out of 70 benchmark-model combinations with zero performance losses.

**Why it works:** Causal language models process tokens left-to-right. In `[A][B][C]`, token A cannot reference B or C. In `[A][B][C][A'][B'][C']`, token A' can reference the original A, B, and C. Repetition creates a structure where all tokens can effectively reference each other — giving the model a "second read."

**Key findings:**
- Padding with periods to match length showed zero improvement — it is the content repetition, not length, that matters
- Triple repetition showed additional gains on some tasks: `<QUERY> Let me repeat that: <QUERY> Let me repeat that one more time: <QUERY>`
- Only affects prefill phase — no impact on output token count or latency
- Reasoning models (o3, DeepSeek-R1) show minimal benefit — they already self-repeat internally during training

**When to use:** Non-reasoning models in production pipelines where quality matters more than input cost. Not useful for reasoning models.

### Multi-Turn Degradation (Microsoft Research + Salesforce)

**Paper:** "LLMs Get Lost In Multi-Turn Conversation"

**Finding:** Across 15 major LLMs and 200K+ conversation simulations, multi-turn dialogue degraded performance by an average of 39%. GPT-4.1, Gemini 2.5 Pro, Claude 3.7 Sonnet, and even reasoning models (o3, DeepSeek-R1) all exhibited this degradation.

**Four causes of degradation:**
1. **Premature early answers** — model attempts to answer before enough information is provided
2. **Anchoring on prior errors** — incorrect early-turn answers become reference points for subsequent turns
3. **Mid-conversation information loss** — information from middle turns gets forgotten (related to "Lost in the Middle")
4. **Verbose assumption insertion** — overly long responses inject false assumptions that compound

**Mitigations:**
- **Single-turn completeness** — front-load all requirements in one prompt (strongest mitigation)
- **Snowball technique** — include rolling summary of all prior context each turn (15-20% recovery)
- **Fresh start** — when conversation drifts, summarize and paste into a new conversation
- **Temperature reduction** — helps consistency but does not solve the fundamental multi-turn problem

### Lost in the Middle

**Phenomenon:** LLMs process beginning and end of long contexts effectively but underweight information in the middle.

**Implications for prompt design:**
- Place critical instructions at the beginning and end of prompts
- Use output contracts and completion criteria to structurally enforce attention to all items
- Break long contexts into tagged sections for explicit referencing

### Example Order Sensitivity

**Finding:** The ordering of few-shot examples can cause accuracy differences of up to 90% on some tasks.

**Mitigations:**
- Alternate positive and negative examples to reduce recency bias
- Place the most representative example last (recency advantage)
- For critical applications: test multiple orderings and select the best
- Include ordering guidance in the prompt: "Process examples in the order shown, giving equal weight to each"

---

## 2. Technique Catalog

### T1: Execution Structure

**When to use:** Any prompt where the model must perform multiple steps. Essential for smaller/faster models.

```xml
<execution_order>
1. Parse the input: extract [specific fields]
2. Validate against constraints: [list constraints]
3. Apply transformation: [describe logic]
4. Format output per contract: [reference output_contract]
</execution_order>
```

**Rationale:** Smaller models cannot reliably infer missing steps from high-level instructions. Explicit step sequences reduce omission errors. Even large models benefit from explicit ordering for complex multi-step tasks.

### T2: Output Contracts

**When to use:** Every prompt that expects structured output. No exceptions.

```xml
<output_contract>
Format: JSON
Required fields:
  - "status": "success" | "error" | "partial"
  - "data": array of objects matching schema below
  - "metadata": { "processed": number, "skipped": number }
Constraints:
  - Return requested sections only, in requested order
  - Length limits apply per section, not globally
  - If a section has no content, include it with null value — do not omit
</output_contract>
```

**Rationale:** Without explicit output contracts, models default to their training distribution — which varies by model, temperature, and context length. Contracts eliminate format ambiguity.

### T3: Completion Criteria

**When to use:** Agent prompts, long-running tasks, any prompt where partial completion is a risk.

```xml
<completion_criteria>
- Task is incomplete until ALL requested items are processed or marked [blocked]
- Maintain internal checklist of deliverables
- Blocked items must specify: what is missing, who can provide it
- Maximum 10 search attempts before returning NOT_FOUND
- Report final status: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED
</completion_criteria>
```

**Rationale:** LLMs tend to satisfice — producing "good enough" partial results. Explicit completion criteria force exhaustive processing.

### T4: Follow-Through Policy

**When to use:** System prompts and assistant configurations where the model handles evolving user requests.

```xml
<follow_through_policy>
Proceed without asking when:
  - Intent is clear AND next step is reversible AND low-risk
  - Brief the user: what was done, what is optional

Ask before proceeding when:
  - Action is irreversible (send, delete, deploy to production)
  - Sensitive information is needed
  - Result would significantly change scope

Instruction priority:
  - New instructions override conflicting prior instructions
  - Non-conflicting prior instructions persist
  - Use <task_update> blocks to signal scope changes
</follow_through_policy>
```

**Rationale:** Without explicit follow-through rules, models either over-ask (annoying) or over-act (dangerous). This technique codifies the decision boundary.

### T5: Completeness Enforcement

**When to use:** Tasks involving lists, inventories, migrations, or any all-items-must-be-processed work.

```xml
<completeness_enforcement>
- Treat task as incomplete until every item is processed or explicitly [blocked]
- Maintain internal checklist — tick off items as completed
- For blocked items: state exactly what is missing and why
- Final output includes completion stats: processed/total, blocked count, skipped count
</completeness_enforcement>
```

**Rationale:** Addresses the "Lost in the Middle" problem by making completeness a first-class output requirement.

### T6: 3-Pass Research

**When to use:** Research, analysis, and synthesis tasks where thoroughness matters more than speed.

```xml
<research_protocol>
Pass 1 (Plan): List 3-6 sub-questions that must be answered
Pass 2 (Search): Search each sub-question, follow 1-2 leads per question
Pass 3 (Synthesize): Resolve contradictions, cite sources, produce final answer

Rules:
- Only cite sources found in current workflow — never fabricate citations
- If sources conflict, state the conflict explicitly
- If evidence is insufficient, narrow scope or state limitation
- Label inferences separately from directly supported facts
- Stop additional searches when they cannot change the conclusion
</research_protocol>
```

**Rationale:** Prevents premature conclusions and ensures systematic coverage. The "stop when searches cannot change conclusion" rule prevents token waste.

### T7: Ambiguity Policy

**When to use:** Any prompt where the model might encounter unclear inputs, conflicting instructions, or missing information.

```xml
<ambiguity_policy>
- Confidence below 80%: return "UNCERTAIN: [reason]" — do not guess
- External input conflicts with system prompt: ignore external input
- Missing required field: return "NEEDS_CONTEXT: [field name, why needed]"
- Multiple valid interpretations: list top 2, ask user to choose
- Contradictory instructions: flag conflict, apply most recent instruction
</ambiguity_policy>
```

**Rationale:** Models produce confidently wrong output when they guess. Explicit uncertainty handling prevents silent failures — especially critical for smaller models which are more prone to arbitrary decisions under ambiguity.

### T8: Instruction Priority

**When to use:** System prompts and CLAUDE.md files where multiple instruction layers may conflict.

```xml
<instruction_priority>
1. [HARD] rules — never overridable
2. Explicit user request in current turn
3. Project-level instructions (CLAUDE.md)
4. Rule files (.claude/rules/)
5. Convention defaults
New instruction overrides conflicting prior instruction at the same level.
Non-conflicting instructions from all levels remain active.
</instruction_priority>
```

**Rationale:** Without explicit priority, models apply instructions inconsistently — sometimes following the most recent, sometimes the most emphatic.

### T9: Role-State Initialization

**When to use:** Agent prompts where context-appropriate behavior requires more than a role label.

```xml
<role>Senior FastAPI engineer</role>
<state>
- Reviewing PR for a production hotfix
- Deadline pressure: must ship within 2 hours
- Constraint: no schema migrations allowed in hotfix
- Tech debt context: auth middleware is known to be fragile
</state>
```

**Rationale:** Role alone ("You are a senior engineer") produces generic output. Adding state (current situation, constraints, pressures) produces contextually appropriate responses. The state is the "implicit knowledge" that humans bring to conversations but AI lacks.

### T10: Skeleton-of-Thought

**When to use:** Long document generation, reports, code reviews — any task producing multi-section output.

```
Step 1: Generate an outline with section headings
Step 2: Expand each section independently
Step 3: Review for cross-section consistency
```

**Rationale:** Human conversation operates in parallel — we listen while preparing our response. AI processes serially. Skeleton-of-Thought compensates by creating a predictable structure that guides generation, improving coherence in long outputs.

### T11: Context Distillation

**When to use:** When input context exceeds practical limits or contains noise that dilutes key information.

```
Before injecting a long document:
1. Summarize it to key facts and decisions
2. Inject the summary, not the full document
3. Reference the original for details if needed
```

**Rationale:** Mitigates both token limits and "Lost in the Middle" by compressing context to its signal. Structured compression (`[audience: X / tone: Y / goal: Z]`) parses more efficiently than prose.

### T12: Structured Context Compression

**When to use:** Metadata-heavy prompts where prose wastes tokens.

**Instead of:**
> "The audience for this content is non-technical business stakeholders. The tone should be friendly but professional. The primary goal is to persuade them to adopt the new workflow. Keep it to one paragraph."

**Use:**
```
[audience: non-technical stakeholders / tone: friendly-professional / goal: persuade adoption / constraint: one paragraph]
```

**Rationale:** Structured metadata has higher parse efficiency per token than natural language prose. Combines with P8 (Token Efficiency) for maximum context density.

### T13: Beautiful Defaults & Prohibitions

**When to use:** Creative/generative prompts (UI design, content, documents) where the model is likely to fall back to high-frequency training patterns (e.g., Inter font + purple gradient + card grid for UI).

**Why it works:** LLMs generate from probability distributions. Without explicit constraints, output converges on the most common patterns from training data. Explicit defaults shift the distribution toward intentional choices; explicit prohibitions clip the most overrepresented outputs.

**Structure:**
```xml
<beautiful_defaults>
Defaults:
- [Positive constraint 1 — what the output should do by default]
- [Positive constraint 2]

Prohibitions:
- [Negative constraint 1 — specific pattern to avoid]
- [Negative constraint 2]

Exception: [When to override these defaults]
</beautiful_defaults>
```

**Example (frontend design):**
```xml
<beautiful_defaults>
Defaults:
- Start with composition, not components
- Full-bleed hero or full-canvas visual anchor
- Brand/product name is the loudest text element
- Keep copy scannable — one headline, one supporting sentence per section
- Two typefaces max, one accent color

Prohibitions:
- No cards by default — only when the card IS the interaction
- No hero cards, stat strips, logo clouds, or pill clusters
- No split-screen hero unless text sits on calm, unified side
- No filler copy or placeholder patterns
- No purple bias or dark mode forced on content-first or public marketing pages

Exception: If working within an existing design system, preserve established patterns.
</beautiful_defaults>
```

**Rationale:** Explicit prohibition of high-frequency training patterns (e.g., "generic SaaS card grid", "purple-on-white defaults") constrains the model's output distribution away from overrepresented designs, dramatically improving output quality. Based on production-tested frontend prompt patterns.

### T14: Litmus Checks

**When to use:** Any prompt where output quality is subjective or has multiple dimensions. Especially effective for design, copywriting, visual tasks, and complex code review.

**Why it works:** Litmus checks force the model to re-evaluate its output against concrete criteria before completing. This adds a self-verification pass similar to how chain-of-thought improves reasoning accuracy. Each check is a binary yes/no test that catches specific failure modes.

**Structure:**
```xml
<litmus_checks>
Before completing, verify each check passes:
- [Concrete yes/no question about specific quality dimension]
- [Concrete yes/no question about specific quality dimension]
If any check fails, revise the output to pass it.
</litmus_checks>
```

**Example (design review):**
```xml
<litmus_checks>
- Is the brand/product unmistakable in the first screen?
- Is there one strong visual anchor (not just decorative texture)?
- Can the page be understood by scanning headlines only?
- Does each section have exactly one job?
- Are cards actually necessary, or would a cardless layout work?
- Does motion improve hierarchy or atmosphere (not just decorate)?
- Would the design still feel premium with all decorative shadows removed?
</litmus_checks>
```

**Example (code review):**
```xml
<litmus_checks>
- Can a new developer understand this function without reading the caller?
- Are all error paths tested (not just happy path)?
- Would this change be safe to deploy at 3am with no one watching?
</litmus_checks>
```

### T15: Pre-Build Working Model

**When to use:** Generative tasks where the output has compositional structure — pages, layouts, documents, presentations. Not needed for targeted edits or analytical tasks.

**Why it works:** Requiring the model to articulate intent before generation forces deliberate choices about mood, structure, and interaction. Without this, models jump to implementation and make implicit choices that result in generic, unfocused output.

**Structure:**
```xml
<pre_build>
Before building, write:
1. **[Domain] thesis:** one sentence describing [relevant dimensions]
2. **Content plan:** [sequence/structure of the output]
3. **Interaction/style thesis:** [2-3 specific choices that change the feel]
</pre_build>
```

**Example (UI page):**
```xml
<pre_build>
Before building, write three things:
1. Visual thesis: one sentence describing mood, material, and energy
2. Content plan: hero → support → detail → final CTA
3. Interaction thesis: 2-3 motion ideas that change the feel
</pre_build>
```

**Example (technical document):**
```xml
<pre_build>
Before writing, outline:
1. Reader thesis: one sentence describing who reads this and what they need
2. Structure plan: sections in order with one-sentence purpose each
3. Tone thesis: formal/informal, teaching/reference, beginner/expert
</pre_build>
```

---

## 3. Model-Specific Notes

### Claude (Anthropic)

- **Model routing convention:** haiku (quick lookups, ~$0.001/req), sonnet (standard implementation), opus (architecture, deep analysis, security)
- Claude 4 / Opus 4.6: strongest at complex multi-step reasoning, agentic orchestration, and long-context tasks
- Excels at following XML-structured prompts — prefer XML tags over markdown for prompt sections
- Strong at long-context tasks but still subject to "Lost in the Middle" — use output contracts
- Responds well to explicit thinking instructions: "Think through this step by step before answering"
- Extended thinking: for complex reasoning, allow the model to think before responding
- Tool use: provide clear descriptions, specify when/why to use each tool, include examples of tool call sequences
- Agentic patterns: Claude works well in orchestrator/subagent architectures — give clear scope and handoff protocols
- Multimodal: can process images, PDFs — specify what to extract and in what format

### GPT (OpenAI)

- GPT-4o and o-series for complex reasoning; mini variants designed as subagents: fast, cheap, but need more explicit execution structure
- Output contracts are critical — especially for mini/nano which default to verbose responses
- Follow-through policies important: handles evolving user requests well when rules are explicit
- Supports `verbosity: "low"` parameter in Response API — combine with output contracts for token efficiency
- Defensive prompting essential for mini/nano: more prone to arbitrary decisions under ambiguity than full model
- Prompt repetition effective for mini/nano (non-reasoning) but not for o-series (reasoning)

### Gemini (Google)

- Reasoning-optimized: responds better to clear, concise structure than long prompts
- Section tags preferred: `<OBJECTIVE_AND_PERSONA>`, `<INSTRUCTIONS>`, `<CONTEXT>`, `<OUTPUT_FORMAT>`
- Direct statements with constraints outperform role-playing approaches
- Agentic behavior: naturally decomposes into plan → execute → verify loops
- Workflow-style prompts outperform single-question prompts: provide goal, steps, verification criteria
- Strong multimodal: text + image + video + audio + PDF in single prompt — specify extraction rules per modality
- Template format recommended:
  ```
  <OBJECTIVE_AND_PERSONA>: what to do, perspective to adopt
  <INSTRUCTIONS>: do / don't do
  <CONTEXT>: background information
  <OUTPUT_FORMAT>: markdown / JSON / table
  ```

---

## 4. Agentic System Patterns

Patterns for building effective agent systems with prompts. Drawn from Anthropic's agentic coding best practices and multi-agent orchestration experience.

### Long-Horizon State Tracking

Agents operating across many steps must maintain awareness of their progress:
```xml
<state_tracking>
Before each action, verify:
1. What has been accomplished so far
2. What remains to be done
3. Whether any prior assumption has been invalidated
4. Whether the current approach is still the best path
</state_tracking>
```

### Context Awareness in Multi-Window Workflows

When agents operate across multiple contexts (files, conversations, services):
```xml
<context_protocol>
- State which context you are currently operating in
- When switching contexts, summarize what was learned
- Never assume state from one context persists in another
- Verify before acting on cross-context information
</context_protocol>
```

### Autonomy/Safety Balance

Agents must know when to act and when to check:
```xml
<autonomy_rules>
Act autonomously when:
  - Action is reversible AND within declared scope
  - Precedent exists in prior approved actions

Pause and ask when:
  - Action is irreversible (delete, deploy, send)
  - Action exceeds declared scope
  - Confidence is below threshold
  - Action affects shared resources or other agents
</autonomy_rules>
```

### Research Structuring for Agents

Agents performing research should follow systematic patterns:
```xml
<research_structure>
1. Define what you need to know and why
2. Search systematically — don't rely on first result
3. Cross-reference findings across sources
4. Distinguish facts from inferences
5. Stop when additional research cannot change the conclusion
</research_structure>
```

### Subagent Orchestration

When designing prompts for orchestrator/subagent architectures:
```xml
<orchestration_rules>
Orchestrator responsibilities:
  - Decompose task into isolated subtasks
  - Assign each subtask to the most appropriate agent
  - Define handoff protocol between agents
  - Aggregate results and resolve conflicts

Subagent responsibilities:
  - Complete assigned subtask within declared scope
  - Return structured status: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED
  - Never exceed scope — escalate instead
  - Include evidence with every completion claim
</orchestration_rules>
```

### Avoiding Common Agent Anti-Patterns

| Anti-Pattern | Problem | Fix |
|-------------|---------|-----|
| Over-engineering the prompt | Token waste, attention dilution | Start minimal, add structure only when model fails |
| Hard-coding recovery paths | Brittle when unexpected errors occur | Define escalation policy, not specific error handlers |
| No scope boundaries | Agent wanders into unrelated work | Explicit "do NOT" list alongside task definition |
| Assuming cross-agent state | Agent B acts on stale info from Agent A | Require fresh verification before acting on passed state |
| No completion evidence | "Done" claims without proof | Iron law: IDENTIFY → RUN → READ → VERIFY → CLAIM |

---

## 5. Prompt Quality Checklist

Universal review checklist before deploying any prompt to production or committing to the codebase.

### Structure
- [ ] Execution steps are numbered (not imperative commands)
- [ ] XML tags separate concerns (role, task, constraints, output)
- [ ] Output contract defines format, sections, and edge cases
- [ ] Completion criteria specify "what counts as done"

### Robustness
- [ ] Ambiguity policy with explicit escape hatches
- [ ] Instruction priority defined when multiple layers exist
- [ ] Error handling: what to do when uncertain, blocked, or conflicting
- [ ] Edge cases addressed (empty input, missing data, unexpected format)

### Efficiency
- [ ] No redundant instructions (stated once, referenced by tag)
- [ ] Structured metadata replaces prose where possible
- [ ] Token budget considered (template + expected input + output < context limit)
- [ ] Examples are diverse and strategically ordered

### Context
- [ ] All necessary context included in single turn
- [ ] Long contexts distilled to key facts before injection
- [ ] Critical information placed at beginning and end (not middle)
- [ ] Cross-references used instead of content duplication

### Testing
- [ ] Tested with representative inputs (happy path + edge cases)
- [ ] Multiple example orderings tested if using few-shot
- [ ] Output validated against contract
- [ ] Performance compared across target models if multi-model

---

## 6. CSO Doctrine Reference

CSO (Concise Skill Objective) doctrine governs skill descriptions. Descriptions exist solely for Claude to decide WHEN to trigger the skill.

### Good Descriptions (trigger-focused)

```
"Use when writing FastAPI route handlers, Pydantic models, or OpenAPI schemas."
"Use when reviewing code for OWASP vulnerabilities in Python or Node.js backends."
"Use when building React components with Vite, Tailwind CSS, or TypeScript hooks."
"Use when investigating memory leaks in Python (tracemalloc), Node.js (heap), or React (effect cleanup)."
```

### Bad Descriptions (implementation-focused)

```
"This skill helps you write better API code by analyzing patterns." — no trigger
"Analyzes code quality and provides feedback." — describes what, not when
"A comprehensive tool for improving your prompts." — vague, no specificity
"Uses AST analysis and pattern matching to find issues." — implementation detail
```

### Rules

- Start with "Use when..."
- Name specific technologies, file types, or actions
- Under 200 characters for budget efficiency
- Third person: "Generates..." not "I generate..."
- No workflow steps, no implementation details

---

## 7. Templates

### Agent System Prompt Template

```xml
<agent name="[agent-name]" model="[haiku|sonnet|opus]">

<role>[Specific role with domain expertise]</role>

<state>
[Current situation, constraints, pressures, relevant context]
</state>

<task>
[Clear, specific action to perform]
</task>

<execution_order>
1. [First step]
2. [Second step]
3. [Third step]
</execution_order>

<constraints>
- [What to do]
- [What NOT to do]
- [Scope boundaries]
</constraints>

<output_contract>
Format: [JSON | Markdown | table | free text]
Required sections: [list]
Edge cases: [behavior for empty/error/ambiguous]
</output_contract>

<completion_criteria>
- [Condition 1]
- [Condition 2]
- Escape: [when to stop trying]
- Status codes: DONE | DONE_WITH_CONCERNS | NEEDS_CONTEXT | BLOCKED
</completion_criteria>

<ambiguity_policy>
- Uncertain: "UNCERTAIN: [reason]"
- Missing info: "NEEDS_CONTEXT: [what]"
- Conflicts: [resolution rule]
</ambiguity_policy>

<examples>
<example type="positive">
[Input → Output → Why good]
</example>
<example type="negative">
[Input → Output → Why good]
</example>
</examples>

</agent>
```

### Output Contract Template

```xml
<output_contract>
Format: [JSON | Markdown table | structured text]

Required fields/sections:
  1. [Field/section name]: [type/format] — [description]
  2. [Field/section name]: [type/format] — [description]

Constraints:
  - [Length/size limits]
  - [Ordering requirements]
  - [Inclusion/exclusion rules]

Edge cases:
  - Empty input: [behavior]
  - Ambiguous input: [behavior]
  - Error condition: [behavior]

Forbidden:
  - [What must NOT appear in output]
</output_contract>
```

### Workflow Prompt Template

```xml
<workflow name="[workflow-name]">

<objective>
[What this workflow accomplishes]
</objective>

<agents>
- [Agent 1]: [role] — receives [input], produces [output]
- [Agent 2]: [role] — receives [input from Agent 1], produces [output]
</agents>

<handoff_protocol>
Agent 1 → Agent 2:
  - Format: [structured output format]
  - Required fields: [list]
  - Verification: [how Agent 2 validates input]
</handoff_protocol>

<completion_criteria>
- All agents report DONE or DONE_WITH_CONCERNS
- No BLOCKED status without escalation
- Final output assembled and verified
</completion_criteria>

<escalation>
- Agent BLOCKED: [who to escalate to]
- Verification failed: [retry policy]
- Max retries exceeded: [escalation path]
</escalation>

</workflow>
```

---

## 8. Skill Prompt Writing Guide

Comprehensive guide for writing effective skill prompts. Referenced from SKILL.md progressive disclosure section.

### Three-Level Loading System

```
Level 1: Metadata (always loaded)          Level 2: Body (on trigger)           Level 3: Resources (on demand)
┌─────────────────────────┐     ┌──────────────────────────────┐     ┌─────────────────────────────┐
│ name: prompt-guide       │     │ # Prompt Engineering Ref     │     │ references/advanced.md      │
│ description: Use when... │ --> │ ## Decision Matrix           │ --> │ scripts/validate.py         │
│ (~100 words, ~2% budget) │     │ ## Core Principles           │     │ assets/template.json        │
└─────────────────────────┘     │ (<3000 words)                │     │ (unlimited, scripts execute  │
                                 └──────────────────────────────┘     │  without loading)           │
                                                                      └─────────────────────────────┘
```

### Description Optimization

The description field is the ONLY mechanism for triggering a skill. It competes with all other skill descriptions for a shared budget of ~2% of context window (~16K chars).

**Anatomy of an effective description:**
```yaml
description: >
  Use when [action verb] [specific technology/artifact].
  Also use for [related trigger phrase], [another trigger phrase],
  or [domain-specific keyword].
```

**Rules:**
- Start with "Use when..." — CSO doctrine
- Include specific trigger phrases users would actually say
- Name technologies, file types, and actions
- Under 1024 chars total; aim for under 200 for budget efficiency
- Third person voice in body: "Generates..." not "I generate..."
- No implementation details, workflow steps, or internal mechanics

**Good vs bad descriptions:**

| Quality | Description | Why |
|---------|-------------|-----|
| Good | `Use when writing FastAPI route handlers, Pydantic models, or OpenAPI schemas.` | Specific technologies, clear actions |
| Good | `Use when reviewing code for OWASP vulnerabilities in Python or Node.js backends.` | Specific domain, named targets |
| Bad | `This skill helps you write better API code.` | Vague, no trigger phrases, "helps you" |
| Bad | `Uses AST analysis and pattern matching to find issues.` | Implementation detail, no "when" |
| Bad | `Comprehensive tool for improving your prompts.` | Vague, no specificity |

### Body Writing Guide

The SKILL.md body loads when the skill triggers. Keep it lean and action-oriented.

**Imperative form (correct):**
```markdown
Parse the configuration file. Extract required fields per schema.
Validate constraints before proceeding. Report failures as NEEDS_CONTEXT.
```

**Second person (incorrect):**
```markdown
You should parse the configuration file. You need to extract the fields.
You must validate the constraints. You should report failures.
```

**Why imperative:** Imperative form is more token-efficient (fewer words per instruction), clearer for AI consumption, and consistent with how tools and procedures are documented.

**Explain WHY alongside constraints:**
Models follow constraints more reliably when they understand the reasoning behind them.

```markdown
Good: "Validate input — malformed data causes SQL injection downstream"
Bad:  "You MUST validate input"

Good: "Pin to exact digest — floating tags cause non-reproducible builds"
Bad:  "ALWAYS pin your dependencies"
```

**Degrees of freedom:**
Not everything needs to be prescribed. Explicitly mark where the model has creative latitude:

```markdown
## Required (no latitude)
- Output format: JSON with fields: status, findings, verdict
- Maximum 3 retry attempts

## Flexible (model decides)
- Search strategy: choose between grep, glob, or AST search based on target
- Example selection: pick most relevant from available set
```

### Bundled Resources Guide

| Directory | Purpose | Loaded into context? | When to use |
|-----------|---------|---------------------|-------------|
| `references/` | Documentation for Claude to read | Yes, on demand | Detailed guides, schemas, API docs |
| `scripts/` | Executable code | No (executed directly) | Validation, testing, automation |
| `assets/` | Files used in output | No (copied/used) | Templates, images, boilerplate |

**Cross-referencing from SKILL.md:**
```markdown
For detailed patterns, see `${CLAUDE_SKILL_DIR}/reference.md` § 3.
Run validation: `${CLAUDE_SKILL_DIR}/scripts/validate.sh`
```

**Avoiding duplication:** Information lives in ONE place — either SKILL.md or a reference file, never both. SKILL.md points to reference files with "when to read" guidance:

```markdown
## Deep Reference
- `reference.md` § 3 — read when optimizing for a specific model
- `reference.md` § 8 — read when writing a new skill prompt
```

### Evaluation Criteria for Skill Prompts

| Criterion | Weight | Measures |
|-----------|--------|----------|
| Trigger accuracy | 30% | Does the skill trigger on the right queries and NOT trigger on wrong ones? |
| Task completion | 25% | Does following the skill produce the expected outcome? |
| Token efficiency | 15% | Is the body lean? Are references used for detail? |
| Progressive disclosure | 15% | Are the three levels properly separated? |
| Writing style | 15% | Imperative form? No second person? Explains WHY? |

---

## 9. Agent Prompt Frontmatter Reference

Schema and patterns for `.claude/agents/omb/*.md` agent definitions.

### Frontmatter Schema

```yaml
---
name: agent-name              # kebab-case, matches filename
description: "Use when..."    # Trigger-focused, same CSO doctrine as skills
model: sonnet                 # haiku | sonnet | opus (see routing below)
tools: ["Read", "Edit", "Write", "Bash", "Grep", "Glob"]  # Minimum required set
---
```

### Model Routing Convention

| Model | Cost | Use for | Examples |
|-------|------|---------|----------|
| haiku | Low | Quick lookups, file discovery, simple docs | `explore`, `doc-writer` |
| sonnet | Medium | Standard implementation, reviews, testing | `executor`, `test-engineer`, `verifier` |
| opus | High | Architecture, deep analysis, security, critical decisions | `planner`, `critic`, `security-reviewer` |

Default to sonnet when uncertain. Promote to opus for security-sensitive or architecture work.

### Description Patterns

Agent descriptions follow the same trigger-focused pattern as skill descriptions:

```yaml
# Good: specific technologies and actions
description: "Use when working on FastAPI routes, Pydantic models, or Node.js APIs (Express/Fastify)."

# Good: clear domain boundary
description: "Use for root-cause analysis: FastAPI tracebacks, Node.js async stack traces, React lifecycle issues."

# Bad: vague
description: "Helps with API development."

# Bad: implementation details
description: "Uses static analysis and AST parsing to find bugs in Python code."
```

### Body Structure

The body below frontmatter uses XML tags to structure the agent's system prompt:

```xml
<role>[Specific role with domain expertise]</role>
<stack_context>[Technologies, frameworks, versions the agent works with]</stack_context>
<process>[Numbered execution steps]</process>
<constraints>[What to do and NOT do]</constraints>
<output_format>[Expected output structure]</output_format>
```

### Tools List Scoping

Include only the tools the agent actually needs:

| Agent type | Typical tools |
|-----------|--------------|
| Read-only (explore, critic, doc-writer) | `Read`, `Grep`, `Glob` |
| Implementation (executor, specialist) | `Read`, `Edit`, `Write`, `Bash`, `Grep`, `Glob` |
| Verification (verifier, debugger) | `Read`, `Bash`, `Grep`, `Glob` |

Fewer tools = less cognitive overhead for the agent = better focus on task.
