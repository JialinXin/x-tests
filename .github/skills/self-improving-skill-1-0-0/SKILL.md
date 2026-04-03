---
name: self-improving-skill-1-0-0
description: "Capture learnings, errors, corrections, and better recurring approaches for continuous improvement. Use when a command or operation fails unexpectedly, when the user corrects the model, when a requested capability does not exist, when an external API or tool fails, when the model realizes its knowledge is outdated or incorrect, when a better repeatable approach is discovered, and before major tasks to review relevant learnings."
---

# Self-Improving Skill

Use this skill to turn mistakes, corrections, failures, and repeat discoveries into durable learning.

## Outcome

This skill helps the model:
- Review past learnings before major work
- Detect moments that should produce a new learning
- Record concise, high-value lessons instead of repeating avoidable mistakes
- Update existing learnings when they are incomplete or wrong
- Tell the user what changed and why it matters

## When To Use

Use this skill when any of the following happens:
- A command, tool, script, build, test, or operation fails unexpectedly
- The user corrects the model, such as "No, that's wrong" or "Actually..."
- The user asks for a capability that does not exist in the current environment
- An external API, MCP tool, service, or integration fails
- The model realizes its knowledge is outdated, incomplete, or incorrect
- A better approach is discovered for a recurring task
- A major task is about to begin and prior learnings should be reviewed first

## Core Principle

Do not treat every event as a memory. Capture only lessons that are likely to matter again.

Good candidates:
- A failure mode that could recur
- A corrected assumption that is easy to repeat by mistake
- A repository-specific convention or limitation
- A workflow improvement that saves time or avoids risk

Bad candidates:
- One-off noise without reuse value
- Raw logs or long transcripts
- Sensitive data, secrets, tokens, or credentials
- Temporary guesses that are not yet verified

## Memory Scopes

Choose the narrowest scope that still preserves useful value.

### User memory: `/memories/`

Store persistent cross-workspace preferences, recurring habits, and stable lessons about how the user likes to work.

### Session memory: `/memories/session/`

Store temporary plans, in-progress context, task-specific findings, and short-lived decisions for the current conversation.

### Repository memory: `/memories/repo/`

Store repository-specific conventions, verified build or test commands, codebase structure facts, and repeated engineering lessons for the current workspace.

## Before Major Tasks

Before substantial implementation, investigation, review, or migration work:
1. Check whether relevant learnings already exist.
2. Prefer viewing existing memory before creating new memory.
3. Bring forward only the learnings that materially affect the task.

Examples of major tasks:
- Multi-file code changes
- Production or Azure operations
- Complex debugging
- Security-sensitive work
- Creating new workflows, skills, prompts, or agents

## Trigger Handling Workflow

### Step 1: Recognize the Trigger

Classify the event:

| Trigger | What to capture |
|---------|------------------|
| Unexpected failure | Root cause, failed assumption, safer retry path |
| User correction | Corrected fact, preferred behavior, prior mistake |
| Missing capability | What was unavailable and the viable alternative |
| External tool or API failure | Failure mode, constraints, fallback path |
| Outdated knowledge | Correct current behavior or source of truth |
| Better recurring approach | The improved method and when to use it |

### Step 2: Decide Whether It Is Worth Storing

Ask:
- Is this likely to happen again?
- Would future work improve if this were remembered?
- Is the lesson concise enough to store as a short note?
- Is it verified rather than speculative?

If the answer is mostly no, do not store it.

### Step 3: Check Existing Memory First

Before creating a new note:
1. View `/memories/` to understand what already exists.
2. If the lesson is repository-specific, inspect `/memories/repo/`.
3. If it is only relevant to this conversation, inspect `/memories/session/`.
4. If an existing note already covers it, update that note instead of creating a duplicate.

### Step 4: Write a Compact Learning

Write the smallest useful note possible.

Preferred format:
- Problem or trigger
- What was learned
- Practical consequence or safer future behavior

Example:
- `Azure MCP command availability depends on configured servers in .vscode/mcp.json; do not assume GitHub automation exists unless a GitHub MCP server is present.`

### Step 5: Tell the User What Changed

When you store or update a learning, briefly state:
- What was learned
- Where it was stored
- Why it matters for future tasks

## Writing Rules

- Keep entries short and specific
- Prefer bullets or one-line facts
- Do not dump stack traces or command output into memory
- Do not store secrets or sensitive identifiers unless the user explicitly asks and it is safe to do so
- Do not create duplicate notes when updating an existing note is enough
- If a previous note turns out to be wrong, correct or remove it

## Fallbacks When Memory Is Unavailable

If the memory tools are unavailable:
1. State that persistent memory could not be updated.
2. Summarize the learning in the conversation.
3. If appropriate, write the learning into a workspace note such as `logs/` or another user-approved location.

## Output Format

When this skill triggers, use a short structure like this:

```markdown
Learning Check
- Trigger: <what happened>
- Decision: <store / update / skip>
- Scope: <user / session / repo / none>
- Learning: <concise lesson>
- Impact: <how this changes future work>
```

## Examples

### Example 1: User Correction

Trigger:
- The user says the current repo uses GitHub Issues as the primary workflow, not Azure DevOps.

Good learning:
- `This workspace uses GitHub Issues as the primary work-tracking surface; ADO is auxiliary only unless the user changes the workflow.`

### Example 2: Missing Capability

Trigger:
- The model assumes GitHub issue automation exists, but no GitHub MCP server is configured.

Good learning:
- `Do not assume GitHub automation in this workspace without an explicit GitHub MCP integration; treat GitHub issue work as a process requirement rather than a guaranteed tool capability.`

### Example 3: Better Approach

Trigger:
- A repeated task becomes easier after using a standard checklist before edits.

Good learning:
- `Before creating or editing workspace customizations, read the relevant SKILL.md or instruction file first; this prevents invalid frontmatter and poor trigger descriptions.`

## Completion Check

Before leaving this workflow, confirm:
- The lesson is real and reusable
- The scope is correct
- Existing memory was checked first
- The stored text is concise
- The user was informed of the update when a memory change was made

## Do Not Overfit

This skill is for durable improvement, not for recording every bump in the road. Prefer a small number of accurate, reusable learnings over a large pile of noisy notes.