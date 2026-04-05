---
description: "LangChain/LangGraph standards: state machines, nodes, edges, tools, checkpointing"
paths: ["**/graphs/**", "**/chains/**", "**/agents/**/*.py"]
---

## Reference Skills

For detailed code examples, API patterns, and common mistakes, consult these reference skills:

| Skill | Covers |
|-------|--------|
| `/omb:lc-langgraph-fundamentals` | StateGraph, nodes, edges, Command, Send, streaming, error handling |
| `/omb:lc-langgraph-persistence` | Checkpointers, thread_id, time travel, Store, subgraph scoping |
| `/omb:lc-langgraph-hitl` | interrupt(), Command(resume), approval workflows, validation loops |
| `/omb:lc-langchain-fundamentals` | create_agent(), @tool decorator, middleware, structured output |
| `/omb:lc-langchain-rag` | RAG pipeline: document loaders, splitters, embeddings, vector stores |

# LangChain / LangGraph Standards

## State Design

- Define state as a typed `TypedDict` — every field explicitly declared.
- Keep state minimal: only data needed for decision-making and output.
- Use `Annotated` fields with reducers for append-only state (e.g., message lists).

```python
from typing import Annotated, TypedDict
from langgraph.graph import add_messages

class AgentState(TypedDict):
    messages: Annotated[list, add_messages]
    current_step: str
    context: dict
```

## Graph Construction

- Use `StateGraph` for stateful workflows.
- Nodes are pure functions: `(state) -> partial state update`.
- Conditional edges for branching logic — keep routing functions simple.
- Name nodes descriptively: `retrieve_context`, `generate_response`, `validate_output`.

```python
from langgraph.graph import StateGraph, END

graph = StateGraph(AgentState)
graph.add_node("retrieve", retrieve_node)
graph.add_node("generate", generate_node)
graph.add_node("validate", validate_node)

graph.add_edge("retrieve", "generate")
graph.add_conditional_edges("validate", should_retry, {"retry": "generate", "done": END})
graph.set_entry_point("retrieve")
```

## Tool Design

- Tools are functions with clear `name`, `description`, and typed parameters.
- Descriptions are prompts — the LLM reads them to decide when to use the tool.
- Keep tools focused: one action per tool.
- Validate tool inputs — don't trust LLM-generated parameters blindly.

## Checkpointing

- Enable checkpointing for any workflow that may need pause/resume or debugging.
- Use `MemorySaver` for development, persistent backend (Postgres) for production.
- Checkpoint after expensive operations (LLM calls, external API calls).

## Error Handling

- Wrap LLM calls in retry logic with exponential backoff.
- Handle tool execution failures gracefully — return error to LLM, don't crash the graph.
- Set max iterations to prevent infinite loops in agent cycles.

## Testing

- Unit test nodes in isolation with mocked state.
- Mock LLM responses for deterministic tests.
- Test graph topology: verify edges and conditional routing.
- Integration test full graph execution with mocked LLM but real tools.

## Anti-Patterns

- State explosion: too many fields, unclear ownership.
- God nodes: one node doing everything.
- Unbounded loops: agent cycles without max iteration limits.
- Hardcoded prompts in nodes — externalize to configuration.
