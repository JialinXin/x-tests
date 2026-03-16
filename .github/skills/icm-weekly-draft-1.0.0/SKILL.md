---
name: icm-weekly-draft-1.0.0
description: "Create a weekly draft ICM summary for Azure SignalR Service triage using ICM MCP data. Use when the user asks for an ICM weekly report, incident weekly summary, weekly incident draft, weekly IcM整理, incident digest, oncall weekly incident notes, or wants a last-week UTC summary of Azure SignalR Service triage incidents with table columns for time, severity, status, root cause, error message, and notes. Also use when the user wants to summarize active incidents first and keep mitigated incidents compact."
---

# ICM Weekly Draft

Build a draft weekly incident summary for Azure SignalR Service triage. The output is a working draft, not a final RCA document. Collect and merge basic information, fill time and incident links, leave owner-only fields such as root cause or deep error details blank when evidence is weak, and generate concise notes from one or two representative incidents for each recurring problem family.

## Prerequisites

This skill requires:
- **ICM MCP** — `mcp_icm_mcp_serve_search_incidents_by_owning_team_id` and `mcp_icm_mcp_serve_get_incident_details_by_id`
- **Optional ICM MCP enrichment** — `mcp_icm_mcp_serve_get_ai_summary`, `mcp_icm_mcp_serve_get_mitigation_hints`, `mcp_icm_mcp_serve_get_similar_incidents`, `mcp_icm_mcp_serve_get_incident_context`
- **Optional webpage or browser tools** — use when discussion content or portal-rendered details are needed and reachable

Read `references/icm-config.md` for the fixed service and team filters, `references/report-format.md` for the target column format, and `references/notes-synthesis-guide.md` for how to generate draft notes safely.

## Scope

This skill is for a **draft** weekly summary.

Fill automatically when possible:
- incident time
- incident title with clickable ICM link
- severity
- status
- occurrence or hit count when available
- customer impact flag when available
- concise notes

Leave blank by default unless strong evidence exists:
- root cause
- error message
- external team bug or escalation details

## Default Time Window

If the user does not provide a date range, summarize the **previous full UTC week**:
- start: Monday `00:00:00.000Z`
- end: Sunday `23:59:59.999Z`

If the user provides a week, explicit dates, or asks for only active incidents, honor that override.

## Workflow

### Step 1: Resolve Filters

Read `references/icm-config.md` and use these verified defaults:
- owning service: Azure SignalR Service
- owning service ID: `23656`
- owning team: Triage
- owning team ID: `44302`

The primary retrieval method is by owning team, then local filtering.

### Step 2: Fetch Candidate Incidents

Call:

```text
mcp_icm_mcp_serve_search_incidents_by_owning_team_id({ teamId: 44302 })
```

Filter the result locally to incidents where:
- `owningServiceId == 23656`
- `owningTeamId == 44302`
- the incident falls in the target time window based on `createdDate`, or `impactStartTime` when present and more representative

Keep both `ACTIVE` and `MITIGATED` incidents unless the user requested a narrower subset.

### Step 3: Split Active And Mitigated

Render the report in two logical tiers:
- **Active incidents first** — individual rows, highest priority
- **Mitigated incidents second** — compact rows or grouped notes when the same family repeats often

Treat auto-mitigated incidents as likely transient unless the details indicate otherwise.

### Step 4: Enrich Incidents

For each active incident, always call:

```text
mcp_icm_mcp_serve_get_incident_details_by_id({ incidentId })
```

For mitigated incidents, call details for:
- incidents that look novel or suspicious
- one or two representative incidents per recurring family

Use optional enrichment when it adds value:
- `mcp_icm_mcp_serve_get_ai_summary` if non-empty
- `mcp_icm_mcp_serve_get_mitigation_hints` to detect known transient patterns
- `mcp_icm_mcp_serve_get_similar_incidents` for recurring issues
- `mcp_icm_mcp_serve_get_incident_context` only when available; do not block the report if it fails

### Step 5: Review Discussion When Reachable

If ICM discussion content is reachable through the available tools, inspect one or two representative incidents for each active problem family and capture a short operational note.

Use this order:
1. ICM-native discussion or context content if available
2. Portal content through webpage or browser tools if readable
3. Incident detail fields, mitigation fields, similar incidents, and title patterns as fallback

If discussion is not reachable, still produce the draft and make the `Notes` cell explicitly draft-quality.

### Step 6: Group Recurring Problems

Normalize recurring incidents by stable title signature. Prefer the bracketed family prefix and the durable stem of the title.

Examples:
- `[KubeNodeConnectivity]`
- `[ACSWarning]`
- `[TableErrors]`
- `[RPFailedAsyncOp]`
- `[SubscriptionReachingQuotaLimit]`

For each recurring family:
- inspect one or two representative incidents
- summarize the pattern once in `Notes`
- keep separate rows when the incidents are still independently important, especially if they remain active

Do not over-merge unrelated issues that merely share a region or resource type.

### Step 7: Fill Report Columns

Use the exact column order from `references/report-format.md`.

Column guidance:
- **Day / time**: use UTC and prefer `impactStartTime`, otherwise `createdDate`
- **RP / Run / Reported by customer**: short classification only, not a long sentence
- **Severity**: numeric severity from ICM
- **Status**: `ACTIVE`, `MITIGATED`, or another ICM state verbatim
- **# of customer impact**: use customer impact signal or support request context when available; otherwise leave blank
- **# of occurrence**: prefer `hitCount` when meaningful; otherwise leave blank
- **Root cause**: leave blank unless strongly supported
- **Bug and/or ICM to external team**: only fill when evidence clearly shows an external handoff, linked bug, or partner incident
- **Error msg**: keep brief; if the available message is noisy stack text, either compress it to a short phrase or leave blank
- **Notes**: concise draft summary grounded in one or two inspected incidents

### Step 8: Render Output

Save the report to:

```text
output/ICM_Weekly/{yyyyMMdd_HHmmss}_draft.md
```

Use UTC timestamp naming.

At the top, include:
- report week range
- service and team filters
- active count
- mitigated count
- short highlights section with the main active families and any unusual mitigated trend

### Step 9: Keep Draft Quality Honest

The report is for owner follow-up. Do not fabricate RCA content.

When evidence is weak:
- leave `Root cause` blank
- leave `Error msg` blank or minimal
- use `Notes` to say what is currently observable, for example `Looks transient and auto-mitigated`, `Recurring connectivity alert family`, or `Needs owner to confirm root cause from discussion`

## Output Template

Use this structure:

```markdown
# ICM Weekly Draft - {week label}

**Service**: Azure SignalR Service
**Owning Team**: Triage
**UTC Window**: {start} - {end}
**Active Incidents**: {activeCount}
**Mitigated Incidents**: {mitigatedCount}

## Highlights

- {short active summary}
- {short mitigated trend summary}

## Active Incidents

| Day / time | RP / Run / Reported by customer | Severity | Status | # of customer impact | # of occurrence | Root cause | Bug and/or ICM to external team | Error msg | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| {UTC time} | {classification} | {severity} | {status} | {impact} | {occurrence} |  | {external link or blank} | {short error or blank} | {draft note with ICM title link} |

## Mitigated Incidents

| Day / time | RP / Run / Reported by customer | Severity | Status | # of customer impact | # of occurrence | Root cause | Bug and/or ICM to external team | Error msg | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| {UTC time} | {classification} | {severity} | {status} | {impact} | {occurrence} |  |  |  | {compact summary with ICM title link} |
```

Always make the incident title a clickable ICM link in either the `Notes` field or the external-link field when appropriate.

## Classification Guidance

Use a short label in `RP / Run / Reported by customer`:
- `Customer` when clearly customer-reported or support-driven
- `RP` for RP or control-plane failures
- `Runtime` for runtime table, cluster, node, or pod health style alerts
- `Infra` for quota, networking, node, or platform dependency issues
- `Security` for security or certificate issues
- `Unknown` when the title does not justify a stronger claim

Do not turn this field into a narrative paragraph.

## Important Notes

- Prefer factual draft notes over confident but unsupported RCA statements.
- Active incidents should almost always stay as separate rows.
- Mitigated incidents can be compressed when many rows are obviously the same transient family.
- If a representative incident points to a clear known issue, reuse that wording carefully across the family and say it is based on sampled incidents.
- When discussion content is unavailable, state that owner follow-up is needed instead of guessing.

## Quick Reference

| Situation | Action |
| --- | --- |
| User asks for last week's ICM summary | Run full workflow with default UTC week |
| User asks only for active incidents | Filter to active after retrieval |
| User asks to mirror the sample report | Use the report template exactly and keep owner-only fields blank unless evidence is strong |
| Many mitigated incidents are repetitive | Group operationally in notes but keep important outliers visible |
| Discussion is inaccessible | Degrade gracefully and mark notes as draft |