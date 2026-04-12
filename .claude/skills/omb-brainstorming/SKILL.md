---
name: omb-brainstorming
description: "Collaborative dialogue for exploring ideas — asks one question at a time to refine intent, constraints, and approach before design or implementation. Can be invoked standalone or as a sub-step from omb-interview."
user-invocable: true
argument-hint: "[idea or topic to brainstorm]"
allowed-tools: Read, Bash, Grep, Glob, AskUserQuestion, Write, Skill
---

# Brainstorming Ideas Into Designs

Help turn ideas into fully formed designs and specs through natural collaborative dialogue.

Start by understanding the current project context, then ask questions one at a time to refine the idea. Once you understand what you're building, present the design in small sections (200-300 words), checking after each section whether it looks right so far.

## HARD RULES

[HARD] One question at a time — never ask multiple questions in a single message.
[HARD] Multiple choice preferred — use open-ended questions only when choices cannot be enumerated.
[HARD] YAGNI ruthlessly — remove unnecessary features from all designs.
[HARD] Incremental validation — present design in sections, validate each before continuing.
[HARD] Explore alternatives — always propose 2-3 approaches before settling on one.
[HARD] Use AskUserQuestion tool — all questions to the user MUST go through the AskUserQuestion tool, not plain text output. Use labeled options with descriptions for multiple-choice, and rely on the built-in "Other" option for freeform input.

## How to Ask Questions

Every question MUST use the `AskUserQuestion` tool. Never ask questions as plain text output.

### Pattern 1: Approach Selection

When proposing 2-3 approaches with trade-offs:

```
AskUserQuestion:
  question: "How should we handle real-time updates for the dashboard?"
  header: "Approach"
  options:
    - label: "WebSocket (Recommended)"
      description: "Persistent bidirectional connection. Best for high-frequency updates (<1s). More complex server setup."
    - label: "Server-Sent Events"
      description: "One-way server push. Simpler than WebSocket, good for medium-frequency updates (1-5s). Auto-reconnect built in."
    - label: "Polling"
      description: "Simplest to implement. Higher latency (5-30s intervals). Best for low-frequency data."
```

### Pattern 2: Design Validation Checkpoint

After presenting a design section, validate with the user:

```
AskUserQuestion:
  question: "Does the component structure above look right?"
  header: "Validation"
  options:
    - label: "Looks good, continue"
      description: "Proceed to the next section of the design."
    - label: "Needs changes"
      description: "I'll explain what needs to be adjusted."
    - label: "Start over"
      description: "Rethink this section from scratch."
```

### Pattern 3: Scope Refinement

When exploring what to include or exclude:

```
AskUserQuestion:
  question: "Which capabilities should the notification system support in v1?"
  header: "Scope"
  multiSelect: true
  options:
    - label: "Email notifications"
      description: "Transactional emails via SendGrid or SES."
    - label: "In-app notifications"
      description: "Real-time bell icon with unread count."
    - label: "Push notifications"
      description: "Mobile/desktop push via FCM or APNs."
    - label: "Slack integration"
      description: "Post to a Slack channel or DM."
```

### Pattern 4: Open-ended with Concrete Starters

When the question is open-ended but you can suggest starting points:

```
AskUserQuestion:
  question: "What's the primary use case for this feature?"
  header: "Use case"
  options:
    - label: "Internal tool"
      description: "Used by the team for operational tasks. Lower polish, higher functionality."
    - label: "Customer-facing"
      description: "End users interact directly. Needs polish, error handling, accessibility."
```

The built-in "Other" option lets the user provide freeform input if neither option fits.

## The Process

**Understanding the idea:**
- Check the current project state first (files, docs, recent commits)
- Ask questions one at a time to refine the idea
- Prefer multiple choice questions when possible, but open-ended is fine too
- Only one question per message — if a topic needs more exploration, break it into multiple questions
- Focus on understanding: purpose, constraints, success criteria

**Exploring approaches:**
- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why

**Presenting the design:**
- Once you believe you understand what you're building, present the design
- Break it into sections of 200-300 words
- Ask after each section whether it looks right so far
- Cover: architecture, components, data flow, error handling, testing
- Be ready to go back and clarify if something doesn't make sense

## After the Design

**Documentation:**
- Write the validated design to `docs/plans/YYYY-MM-DD-<topic>-design.md`
- Use `Skill("omb-doc")` for documentation formatting guidelines
- Commit the design document to git

**Implementation (if continuing):**
- Ask: "Ready to set up for implementation?"
- Suggest `Skill("omb-plan")` or `/omb-plan` to create a detailed implementation plan from the design

## Output Contract

When brainstorming completes successfully (user approves design or signals done):

```
<omb>DONE</omb>
```

```result
verdict: Brainstorming complete
summary: {1-3 sentence summary of the refined idea/design}
artifacts:
  - {design document path, if written}
changed_files:
  - {files created/modified, empty list if none}
concerns:
  - {concerns if any, empty list if none}
blockers: []
retryable: false
next_step_hint: invoke omb-plan for implementation planning
```

When brainstorming is blocked (user cannot decide, contradictory requirements):

```
<omb>BLOCKED</omb>
```

```result
verdict: Brainstorming blocked
summary: {description of what is blocking progress}
artifacts: []
changed_files: []
concerns: []
blockers:
  - {blocking issue description}
retryable: true
next_step_hint: resolve the blocking issue and re-invoke omb-brainstorming
```
