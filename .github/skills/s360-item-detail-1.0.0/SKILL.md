---
name: s360-item-detail-1.0.0
description: "Deep-dive into a specific S360 KPI action item to extract affected Azure ResourceIds, subscription details, and remediation links. Use when the user wants to see which resources are affected by an S360 action item, asks for S360 item details, wants ResourceIds for an S360 KPI, says 'drill into S360 item', 'show resources for this S360 KPI', 'what resources need remediation', or provides an S360 KPI ID / action item ID / action item title to investigate. Also use when the user wants to understand what specific work is needed for an S360 compliance item."
---

# S360 Item Detail

Extract and present detailed resource information for a specific S360 KPI action item group. Different KPI types store resource information differently — this skill dispatches the right extraction strategy automatically.

## Prerequisites

This skill requires:
- **s360-breeze** MCP — `search_active_s360_kpi_action_items`, `get_active_s360_action_item_for_kpi`, `get_s360_kpi_metadata_by_kpi_id`
- **kusto** MCP — `execute_query` for Kusto-backed KPIs (best-effort)
- **fetch_webpage** — For linked documentation (best-effort)

Read `references/resource-extraction-guide.md` for the per-KPI-type extraction strategies and real data examples.

## Workflow

### Step 1: Resolve Input

The user may provide:

| Input | How to handle |
|-------|--------------|
| KPI ID (UUID) | Use directly as `kpiId` |
| KPI action item ID | Use with `get_active_s360_action_item_for_kpi(kpiId, kpiActionItemId)` |
| Title text (e.g., "Disable local auth") | Fetch all items via `search_active_s360_kpi_action_items`, filter by `Title` match |
| S360 URL | Parse `kpiId` from URL path/query parameters |

If only a title is given, use `search_active_s360_kpi_action_items(targetIds=["624c481d-e51c-4016-a522-fbe180d125fc"], pageSize=50)` with pagination, and filter results where `Title` contains or matches the user's text (case-insensitive).

### Step 2: Fetch Items

**For a KPI group** (most common — user wants all items under one KPI):
- Fetch all items via `search_active_s360_kpi_action_items` with pagination
- Filter to items matching the target `KpiId`

**For a single action item**:
- Call `get_active_s360_action_item_for_kpi(kpiId, kpiActionItemId)` directly

### Step 3: Fetch KPI Metadata

Call `get_s360_kpi_metadata_by_kpi_id(kpiId)` to get:
- KPI description and remediation guidance
- Associated data sources (Kusto queries, dashboards)
- KPI category and program info

This provides context for what the KPI measures and how to fix issues.

**Important**: The KPI description often contains TSG links or remediation steps — always check it. TSG links are usually on eng.ms. Some KPIs also embed TSG references in Kusto dashboard descriptions.

### Step 4: Extract Resources

Dispatch based on the data pattern observed in the action items. Read `references/resource-extraction-guide.md` for the full strategy guide.

**Quick dispatch table:**

| Signal in item data | Type | Strategy |
|---------------------|------|----------|
| `CustomDimensions.resourceId` is a full ARM path | Type A | Extract resourceId directly from each item |
| `CustomDimensions.AssetTypeLink0` is an ADX dashboard URL | Type B | Provide dashboard link + TotalCount; optionally parse Kusto query |
| `URL` contains Azure Resource Graph query (portal.azure.com + ArgExplorer) | Type C | Decode the ARG query and present it; extract SubscriptionId, Region |
| `CustomDimensions.ApplicationId` + `reportUrl` present | Type D | Present app info, ReasonFlagged, and report link |
| None of the above | Unknown | Present all available CustomDimensions fields and the URL |

### Step 5: Render Report

Structure the output as:

```markdown
## S360 Item Detail — {KPI Title}

**KPI ID**: {kpiId}
**SLA Status**: {worst SLAState across items} ({count} items)
**Due Date**: {earliest CurrentDueDate}
**Exceptions**: {total ExceptionCount}
**Clouds**: {distinct cloudType values}

### Remediation
- **TSG**: [link]({URL})
- **Wiki**: [link]({ActionWikiLink})  (if available)

### Affected Resources

{Type-specific content — see below}

### Next Steps
{Remediation guidance from KPI metadata if available}
```

**Type A output** (direct resourceId):
```markdown
| # | Resource ID | Subscription | Resource Group | SLA Status | Due Date |
|---|------------|--------------|----------------|------------|----------|
| 1 | /subscriptions/.../signalr/name | 9caf2a1e-... | myresourcegroup | InSla | 2026-06-29 |
```

**Type B output** (aggregated dashboard):
```markdown
**Total Affected**: {TotalCount} ({AssetType0})
**Environments**: {Environments}
**Dashboard**: [View in Azure Data Explorer]({AssetTypeLink0})
**Remediation Wiki**: [Action Guide]({ActionWikiLink})
```

**Type C output** (Azure Resource Graph):
```markdown
**Subscription**: {SubscriptionId}
**Region**: {Region}
**Items to Mitigate**: {ItemsToMitigate}
**VNets to Mitigate**: {TotalVNetsToMitigate}

**Azure Resource Graph Query** (run in Azure Portal → Resource Graph Explorer):
```kusto
{decoded query from URL}
`` `

**Portal Link**: [Open in Azure Portal]({URL})
```

**Type D output** (app-based):
```markdown
| App ID | App Name | Reason Flagged | Cloud | Report |
|--------|----------|----------------|-------|--------|
| {ApplicationId} | {AppName} | {ReasonFlagged} | {cloudType} | [Report]({reportUrl}) |
```

### Step 6: Save to File

Save the report to `Tasks/S360_Dashboard/{yyyyMMdd_HHmmss}_detail_{kpiId_first8chars}.md` using UTC timestamp.

## Quick Reference

| Situation | Action |
|-----------|--------|
| User gives a KPI ID | Fetch all items for that KPI, extract resources |
| User gives a title | Search all items, filter by title, then extract |
| User asks "what resources need fixing for X" | Same as title-based lookup |
| ResourceIds found directly | Show ARM resource table |
| No direct ResourceIds | Provide dashboard/query links with instructions |
| Kusto query available in KPI metadata | Best-effort: try execute via kusto MCP |

## Important Notes

- Resource extraction is **best-effort**. If a source is inaccessible (Kusto cluster auth, private dashboard), provide the link and explain what access is needed rather than failing.
- For Type B (dashboard) items, the `AssetTypeLink0` URL often contains time-bound parameters (`StartDt`, `EndDt`). Mention that the data window is time-scoped and the user may need to refresh the dashboard.
- For Type C (ARG query) items, the URL-encoded query in the `URL` field needs proper decoding (`%0D%0A` → newline, `%7C` → pipe, etc.). Always decode before presenting.
- Some items may have `ExceptionCount > 0`, indicating approved exceptions. Note this when presenting — these items have had their SLA extended.
- The `URL` field serves different purposes per KPI type: it may be an eng.ms TSG doc, an ADX dashboard, or an Azure Portal ARG explorer link. Don't assume it's always a TSG.
- **Where to find TSG docs**: Most TSGs are hosted on eng.ms (check `URL` field and KPI metadata description). Some are referenced in Kusto dashboard descriptions. Always present any eng.ms link prominently as the primary remediation reference.
