# Task Workflow Guide

## Purpose
- Define a consistent structure for task families and their workflow documentation.
- Enable agents to execute tasks autonomously by following clear, repeatable steps.
- Preserve execution history using timestamped run logs for traceability.

## Directory Structure
```text
Tasks/
├─ <T1>/
│  ├─ Workflow.md
│  ├─ yyyyMMddfff.md
│  └─ ...
├─ <T2>/
│  ├─ Workflow.md
│  ├─ yyyyMMddfff.md
│  └─ ...
└─ README.md
```
- `<T1>`, `<T2>` represent task families (one folder per task type).
- Every task folder holds a `Workflow.md` guide plus timestamped run logs named `yyyyMMddfff.md` (`fff` = milliseconds).

## Workflow.md Expectations
- Describe the task objective, prerequisites, and stakeholders.
- Outline the step-by-step execution flow.
- Specify the required inputs, expected outputs, and quality checks.
- Document where to store evidence and how to escalate issues.

## Run Log Expectations
- Capture a concise summary, actions taken, evidence collected, and follow-up items.
- Reference related tickets, artifacts, and communications.
- Keep run logs immutable; create a new timestamped file for corrections or reruns.

## Templates
### Workflow Skeleton
```markdown
# <Task Name> Workflow

## Purpose
- What problem this task solves and the desired outcome.

## Prerequisites
- Access, tools, datasets, or approvals required before starting.

## Standard Flow
1. Intake – confirm scope and success criteria.
2. Plan – outline steps, resources, and test coverage.
3. Prepare – stage environments and validate readiness.
4. Execute – perform scripted/manual checks and capture evidence.
5. Assess – evaluate results, highlight deviations, recommend fixes.
6. Report – publish findings and assign follow-up actions.

## Recording Results
- Naming: `yyyyMMddfff.md` (UTC) stored in this folder.
- Required sections: Summary, Executed Steps, Evidence, Follow-Up.
- Storage: include links/paths to logs, screenshots, tickets.

## Post-Run Checklist
- Notify stakeholders and update tracking systems.
- Log follow-up actions with owners and due dates.
- Archive artifacts in the agreed repository.
```

### Run Log Skeleton (`yyyyMMddfff.md`)
```markdown
# Run yyyyMMddfff

## Summary
- Outcome: <Pass|Fail|Blocked>
- Scope: <systems, controls, tickets>
- Lead: <name or team>

## Executed Steps
| Step | Action | Result | Artifacts |
| --- | --- | --- | --- |
| Intake | ... | ... | ... |
| Plan | ... | ... | ... |
| Prepare | ... | ... | ... |
| Execute | ... | ... | ... |
| Assess | ... | ... | ... |
| Report | ... | ... | ... |

## Evidence
- Logs: <path or URL>
- Screenshots: <path or URL>
- Tickets: <IDs>

## Follow-Up
- <Action item, owner, target date>
```
