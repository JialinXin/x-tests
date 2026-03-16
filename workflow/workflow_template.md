# Workflow Template

## Purpose
- Clarify the objective of the task and the expected outcome.
- Highlight why this workflow exists and what success looks like.

## Prerequisites
- Access requirements (systems, credentials, approvals).
- Tooling or datasets that must be prepared in advance.
- Stakeholders or requestors to align with before execution.

## Roles
- **Request Owner**: Provides scope, success criteria, and approvals.
- **Task Lead**: Coordinates execution, validates results, and escalates blockers.
- **Execution Team**: Performs scripted/manual steps and captures evidence.

## Standard Flow
| Step | Description | Responsible | Inputs | Outputs |
| --- | --- | --- | --- | --- |
| Intake | Confirm scope, success criteria, and timelines. | Request Owner, Task Lead | Request brief, background context | Agreed scope, open questions list |
| Plan | Define test coverage, resources, and timelines. | Task Lead | Control catalog, tooling checklist | Approved execution plan |
| Prepare | Stage environments, data, and monitoring hooks. | Execution Team | Access credentials, scripts, datasets | Ready-to-run environment |
| Execute | Carry out the plan and capture evidence. | Execution Team | Execution plan, tooling | Raw artifacts (logs, screenshots) |
| Assess | Evaluate results, note deviations, recommend fixes. | Task Lead | Raw artifacts, acceptance criteria | Pass/fail matrix, remediation notes |
| Report | Summarize findings, assign follow-up actions. | Task Lead, Request Owner | Assessment summary | Published report, action tracker |

## Recording Results
- After each run, create a new markdown file named `yyyyMMddfff.md` (`fff` = milliseconds, UTC) in this folder.
- Create a log file named `yyyyMMddfff.txt` to capture execution steps: Summary, Executed Steps, Status(Success or Failure reason like exceptions), 
- Do not overwrite historical logs; add a new timestamped file for retests or corrections.

## Evidence Management
- Logs: store in the agreed repository and link by path or URL.
- Screenshots: include filenames or shared locations.
- Tickets/Approvals: reference identifiers and owners.

## Escalation
- Define thresholds for blocking issues and the escalation path.
- Document contact points for tooling failures or access problems.

## Post-Run Checklist
- Notify stakeholders with the report link and key findings.
- Update tracking systems (tickets, dashboards) with references to the run log.
- Schedule remediation or follow-up testing with owners and deadlines.

## Appendices
- **Glossary**: Define domain-specific terms or control IDs.
- **Tooling Links**: Provide quick access to scripts, dashboards, or runbooks.
- **Change History**: Note significant updates to this workflow template.
