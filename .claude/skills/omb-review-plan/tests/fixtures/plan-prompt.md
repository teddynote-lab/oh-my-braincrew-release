## Plan: Prompt Engineering Workflow

### Context
This plan adds a prompt engineering layer to the LLM workflow. We will
implement few-shot examples and chain-of-thought reasoning to improve output
quality.

### Tasks
| # | Task | Agent | Deliverable |
|---|------|-------|-------------|
| 1 | Design prompt template | prompt-engineer | `prompts/base.md` |
| 2 | Add few-shot examples | prompt-engineer | `prompts/examples.md` |
| 3 | Implement chain-of-thought reasoning | executor | `backend/chain.py` |
