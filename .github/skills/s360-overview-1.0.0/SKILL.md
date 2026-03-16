---
name: s360-overview-1.0.0
description: "Summarize and prioritize S360 dashboard action items for the Azure SignalR Service. Shows red/yellow/green status overview grouped by KPI, with due dates, item counts, and links. Use when the user asks about S360 status, S360 dashboard, S360 overview, action items summary, what's overdue in S360, red/yellow items, S360 health, compliance status, or wants to see the current state of S360 KPIs. Also use when the user mentions 'S360', 'service 360', or asks about security compliance action items."
---

# S360 Overview

Retrieve and summarize all active S360 action items for the Azure SignalR Service, classified by SLA status.

## Prerequisites

This skill requires two MCP tools:
- **s360-breeze** — `search_active_s360_kpi_action_items` for fetching action items
- **kusto** — Optional, for KPI metadata enrichment

Read `references/service-config.md` for the service tree targetId and S360 dashboard URL.

## Workflow

### Step 1: Fetch All Active Action Items

Call `search_active_s360_kpi_action_items` with the targetId from `references/service-config.md` and `pageSize=50`. Follow pagination by repeating the call with `cursor=nextCursor` until `nextCursor` is empty or null.

```
Request: search_active_s360_kpi_action_items({
  targetIds: ["624c481d-e51c-4016-a522-fbe180d125fc"],
  pageSize: 50
})
```

For subsequent pages:
```
Request: search_active_s360_kpi_action_items({
  targetIds: ["624c481d-e51c-4016-a522-fbe180d125fc"],
  pageSize: 50,
  cursor: "<nextCursor from previous response>"
})
```

Collect all items from `result.resources` across all pages.

### Step 2: Group by KPI

Many action items share the same KPI and Title but differ by resource. Group items by `(KpiId, Title)` to avoid showing hundreds of rows like "Disable local auth" repeated per resource.

For each group, compute:
- **Item count**: number of action items in this group
- **Worst SLAState**: if any item is `OutOfSla`, the group is Red; if any is `ApproachingSla`, it's Yellow; otherwise Green
- **Earliest CurrentDueDate**: most urgent due date in the group
- **Total ExceptionCount**: sum of exceptions across items
- **CloudType / Environments**: distinct values from `CustomDimensions.cloudType` and `CustomDimensions.Environments`
- **URL**: the TSG/dashboard link (usually the same within a group — use the first non-empty value)
- **ActionWikiLink**: take from `CustomDimensions.ActionWikiLink` if present

### Step 3: Classify by SLA Status

Map the `SLAState` field directly — it is the authoritative source:

| SLAState | Display | Meaning |
|----------|---------|---------|
| `OutOfSla` | 🔴 Red | Overdue — needs immediate action |
| `ApproachingSla` | 🟡 Yellow | Approaching SLA deadline — needs attention soon |
| `InSla` | 🟢 Green | On track |

### Step 4: Render Summary

Present a markdown table ordered by severity (Red → Yellow → Green):

```markdown
## S360 Action Items Overview — {date}

**Service**: Azure SignalR Service (624c481d-e51c-4016-a522-fbe180d125fc)
**Total Items**: {total count across all groups}
**Dashboard**: [S360 Dashboard]({dashboard URL from service-config.md})

### 🔴 Red (Out of SLA)

| KPI Title | KPI ID | Items | Due Date | Exceptions | Clouds | S360 | TSG |
|-----------|--------|-------|----------|------------|--------|------|-----|
| {Title} | `{kpiId}` | {count} | {earliest due} | {exceptions} | {clouds} | [S360]({resolved S360 URL}) | [TSG]({URL}) |

### 🟡 Yellow (Approaching SLA)

(same table format)

### 🟢 Green (In SLA)

(same table format)
```

**S360 link resolution**: Resolve the S360 URL in this exact order:
1. If the S360 API response already includes a dedicated KPI-detail URL for the group, use that exact URL verbatim.
2. Otherwise, use the full people-scoped dashboard URL from `references/service-config.md` exactly as written there.

Do not invent or synthesize a per-KPI S360 URL from `KpiId` alone unless a verified URL template has been documented in `references/service-config.md`. Do not shorten the dashboard fallback to only `peopleBasedNodes=...`; preserve the full URL including the `blade` and `global` parameters.

**TSG column**: Show the `URL` field value (usually an eng.ms TSG doc link). If `CustomDimensions.ActionWikiLink` is also available, show it as a second link.

At the bottom of each severity section, add a brief hint: _"Use s360-item-detail with KPI ID `{kpiId}` to see affected resources."_

### Step 5: Save to File

Save the full report to `output/S360_Dashboard/{yyyyMMdd_HHmmss}_overview.md` using UTC timestamp.

## Quick Reference

| Situation | Action |
|-----------|--------|
| User says "S360 status" / "S360 overview" | Run full workflow |
| User asks "what's overdue" | Run workflow, highlight Red items only |
| User asks about a specific KPI by name | Run workflow, filter to matching group |
| User wants to drill into resources | Suggest s360-item-detail skill with the KPI ID |

## Important Notes

- The API returns items at the individual resource level. Always group by `(KpiId, Title)` for the overview — showing 50+ "Disable local auth" rows defeats the purpose of a summary. This is an initial bird's-eye view; keep it collapsed and concise.
- `SLAState` from the API is the authoritative red/yellow/green classification. Do not recompute from dates — the API accounts for exceptions, ETA extensions, and SLA policies that date math alone would miss.
- Some KPI groups span multiple clouds (Public, Fairfax, Mooncake). Show distinct cloud values in the Clouds column.
- If `ExceptionCount > 0`, mention it — exceptions indicate items with approved SLA overrides.
- Every KPI row **must** include a clickable S360 link. If no verified per-KPI link is available from the API or documented config, use the full dashboard URL and rely on the visible `KPI ID` column for drill-in.
