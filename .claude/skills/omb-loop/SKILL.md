---
name: omb-loop
description: >
  Use when the user wants to run a task on a recurring interval (e.g., "check logs every 10 minutes",
  "monitor errors and auto-fix"). Manages the iteration lifecycle, sub-pipeline orchestration,
  and marker emission for the omb loop system.
user-invocable: true
metadata:
  version: "0.1.0"
  category: "workflow"
  status: "active"
  updated: "2026-03-22"
  tags: "loop, recurring, cron, monitoring, interval"
  argument-hint: "<interval> \"<task description>\""
---

# Loop Skill

## Purpose

Execute a recurring task at a fixed interval. Each iteration runs the task, optionally spawning a sub-pipeline (e.g., fix pipeline), and emits a completion marker for the Stop hook to process.

## Invocation

Via dispatcher: `/omb loop 10min "check docker logs for errors"`
Direct: `omb-loop 10min "check docker logs for errors"`

## Arguments

- First argument: interval (e.g., `10m`, `5min`, `1h`, `30s`)
- Remaining text: task description (quoted or unquoted)

## Execution Flow

1. Parse interval and task description from arguments.
2. Run `omb loop start <interval> "<task>"` to create the loop state.
3. Execute the first iteration:
   a. Perform the task described by the user.
   b. If the task references a pipeline (e.g., "use fix pipeline"), invoke the pipeline skill and wait for completion.
   c. Log iteration results.
4. Emit completion marker: `<omb>LOOP:{loop-id}:ITERATION_DONE</omb>` on success, or `<omb>LOOP:{loop-id}:ITERATION_FAILED:error message</omb>` on failure.
5. The Stop hook processes the marker and either:
   - Blocks stop with a sleep instruction (interval ≤ 15min)
   - Pauses the loop (interval > 15min, resumes next session)
   - Completes the loop (max iterations reached)
   - Fails the loop (too many consecutive failures)

## Sub-Pipeline Sequencing

When a sub-pipeline (e.g., fix pipeline) is part of the task:
- The sub-pipeline runs to completion first (its own STEP: markers processed normally).
- ONLY AFTER the sub-pipeline completes, emit the LOOP: marker in a SEPARATE assistant turn.
- This ensures pipeline and loop markers never collide in the same LastAssistantMessage.

## Management Commands

- `omb loop status` — Show active loop.
- `omb loop cancel` — Cancel the active loop.
- `omb loop list` — List all loops.
- `omb loop pause` — Pause the active loop.
- `omb loop resume` — Resume a paused loop.

## Marker Format

```
<omb>LOOP:{loop-id}:ITERATION_DONE</omb>
<omb>LOOP:{loop-id}:ITERATION_FAILED[:error-msg]</omb>
```
