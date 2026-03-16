name: icm-weekly-draft-1.0.0
description: "Create a weekly draft ICM summary for Azure SignalR Service triage using ICM MCP data. Use when the user asks for an ICM weekly report, incident weekly summary, weekly incident draft, weekly IcM整理, incident digest, oncall weekly incident notes, or wants a last-week UTC summary of Azure SignalR Service triage incidents with table columns for time, severity, status, root cause, error message, and notes. Also use when the user wants to cluster incidents into likely transient issues versus items that need manual review."
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
- owner-filled external escalation details beyond the sampled incident link

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

Keep `ACTIVE`, `MITIGATED` and `RESOLVED` incidents unless the user requested a narrower subset.

Immediately record the filtered weekly incident total before any grouping. This is the baseline count that later aggregation must reconcile against.

### Step 3: Classify Incident Families

Render the report by issue type first, not by lifecycle state:
- **Transient** — recurring, high-volume families where the sampled incidents look auto-mitigated or mostly mitigated
- **Needs manual review** — lower-volume, longer-lived, or unusual families that still need owner investigation or manual mitigation review

Use simple draft heuristics rather than deep RCA:
- if a family appears many times and the sampled incidents are mostly mitigated, treat it as `Transient`
- if a family is uncommon, suspicious, or has incidents still active more than 24 hours after creation, treat it as `Needs manual review`
- keep the factual ICM `Status` on each row, but do not use it as the primary section boundary

### Step 4: Enrich Incidents

Always call details for incidents that may land in `Needs manual review` and for at least one representative incident in every recurring family:

```text
mcp_icm_mcp_serve_get_incident_details_by_id({ incidentId })
```

Call details for a second representative incident when:
- the family looks mixed across states or regions
- the first sample does not clearly support `Transient` versus `Needs manual review`
- the family is low-volume but still suspicious

Use optional enrichment when it adds value:
- `mcp_icm_mcp_serve_get_ai_summary` if non-empty
- `mcp_icm_mcp_serve_get_mitigation_hints` to detect known transient patterns
- `mcp_icm_mcp_serve_get_similar_incidents` for recurring issues
- `mcp_icm_mcp_serve_get_incident_context` only when available; do not block the report if it fails

### Step 5: Review Discussion When Reachable

If ICM discussion content is reachable through the available tools, inspect one or two representative incidents for each problem family and capture a short operational note.

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
- place one sampled incident title with clickable URL in `Bug and/or ICM to external team`
- summarize the pattern and the draft classification rationale once in `Notes`
- keep separate rows only when the incidents are still independently important or the family cannot be represented honestly as one cluster

Do not over-merge unrelated issues that merely share a region or resource type.

After grouping, compute the aggregated total represented by the table:
- prefer summed `# of occurrence` values when they are populated and meaningful for the family
- otherwise fall back to counting the number of incidents represented in that row
- compare the aggregated total to the filtered weekly incident total from Step 2
- if the counts do not match, call out the mismatch in the report header or draft note and mention likely causes such as paging gaps, blank occurrence values, or outliers left ungrouped

### Step 7: Fill Report Columns

Use the exact column order from `references/report-format.md`.

Column guidance:
- **Day / time**: use UTC and prefer `impactStartTime`, otherwise `createdDate`
- **RP / Run / Reported by customer**: short classification only, not a long sentence
- **Severity**: numeric severity from ICM
- **Status**: `ACTIVE`, `MITIGATED`, or another ICM state verbatim
- **# of customer impact**: use customer impact signal or support request context when available; otherwise leave blank
- **# of occurrence**: prefer `hitCount` when meaningful; otherwise use the represented incident count for later reconciliation
- **Root cause**: leave blank unless strongly supported
- **Bug and/or ICM to external team**: place one representative incident title with clickable ICM link for the cluster; if there is also a true external escalation, include it after the sample incident only when concise
- **Error msg**: leave blank by default in this draft workflow; owner follow-up can fill it later if needed
- **Notes**: concise draft summary grounded in one or two inspected incidents, including why the family looks transient or why it still needs manual review

### Step 8: Render Output

Save the report to:

```text
output/ICM_Weekly/{yyyyMMdd_HHmmss}_draft.md
```

Use UTC timestamp naming.

At the top, include:
- report week range
- service and team filters
- filtered weekly incident total from Step 2
- aggregated total represented in the final tables
- a short reconciliation note when the two totals do not match
- short highlights section with the main transient families and the main manual-review items

### Step 9: Keep Draft Quality Honest

The report is for owner follow-up. Do not fabricate RCA content.

When evidence is weak:
- leave `Root cause` blank
- leave `Error msg` blank
- use `Notes` to say what is currently observable, for example `Looks transient based on sampled mitigated incidents`, `Recurring connectivity alert family`, or `Needs owner to confirm root cause from discussion`

## Output Template

Use this structure:

```markdown
# ICM Weekly Draft - {week label}

**Service**: Azure SignalR Service
**Owning Team**: Triage
**UTC Window**: {start} - {end}
**Filtered Weekly Incident Total**: {filteredIncidentTotal}
**Aggregated Table Total**: {aggregatedTableTotal}
**Count Reconciliation**: {matched or mismatch note}

## Highlights

- {short manual-review summary}
- {short transient summary}

## Needs Manual Review

| Day / time | RP / Run / Reported by customer | Severity | Status | # of customer impact | # of occurrence | Root cause | Bug and/or ICM to external team | Error msg | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| {UTC time} | {classification} | {severity} | {status} | {impact} | {occurrence} |  | {sample incident title link} |  | {draft cluster summary and why owner review is still needed} |

## Transient

| Day / time | RP / Run / Reported by customer | Severity | Status | # of customer impact | # of occurrence | Root cause | Bug and/or ICM to external team | Error msg | Notes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| {UTC time} | {classification} | {severity} | {status} | {impact} | {occurrence} |  | {sample incident title link} |  | {draft cluster summary and why it looks transient} |
```

Always make the sampled incident title a clickable ICM link in `Bug and/or ICM to external team`.

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
- A family can contain mixed ICM states; classify it by operational handling rather than by state alone.
- High-volume mostly mitigated families can be compressed into one transient row when the sampled incidents support that summary.
- Low-volume, long-lived, or unusual families should stay visible in `Needs Manual Review` even if some sampled incidents are already mitigated.
- If a representative incident points to a clear known issue, reuse that wording carefully across the family and say it is based on sampled incidents.
- When discussion content is unavailable, state that owner follow-up is needed instead of guessing.

## Quick Reference

| Situation | Action |
| --- | --- |
| User asks for last week's ICM summary | Run full workflow with default UTC week |
| User asks only for active incidents | Filter to active after retrieval |
| User asks to mirror the sample report | Use the report template exactly, but keep issue-type sections and the new count-reconciliation header |
| Many repetitive incidents are mostly mitigated | Group them into `Transient` when the sampled incidents support that summary |
| Discussion is inaccessible | Degrade gracefully and mark notes as draft |