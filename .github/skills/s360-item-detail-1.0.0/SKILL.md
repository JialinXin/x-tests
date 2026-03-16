---
name: s360-item-detail-1.0.0
description: "Multi-hop investigation of an S360 KPI action item: extract affected resources or objects, follow linked evidence recursively, explain what the Azure SignalR Service team must do, and stop only on permission, corpnet, or tooling blockers. Use when the user asks for S360 item details, KPI impact analysis, remediation steps, required follow-up work, or provides an S360 KPI ID, action item ID, title, or related URL."
---

# S360 Item Detail

Investigate a specific S360 KPI action item group deeply. This skill is not limited to listing resources. It should extract affected resources or other affected objects, follow linked evidence until the task is clearly understood, ground the interpretation in Azure SignalR Service context, and synthesize concrete work items the service team must complete.

## Prerequisites

This skill requires:
- **s360-breeze** MCP — `search_active_s360_kpi_action_items`, `get_active_s360_action_item_for_kpi`, `get_s360_kpi_metadata_by_kpi_id`
- **kusto** MCP — `execute_query` for Kusto-backed KPIs when cluster access exists
- **fetch_webpage** — Required for linked docs, TSGs, dashboards, work item pages, and recursive evidence following
- **browser / Playwright-style MCP tools** — Fallback path for rendered pages, redirects, interactive auth flows, or docs that `fetch_webpage` cannot read reliably
- **Azure resource detail source when available** — Optional but preferred for resource owner enrichment when a KPI identifies concrete Azure resources and name-based heuristics are insufficient

Read `references/resource-extraction-guide.md` for the per-KPI-type investigation strategies, real data examples, and blocker handling rules.

## Investigation Goals

1. **Extract affected objects** — Identify which Azure resources, infrastructure objects, applications, dashboards, or workflow items are flagged by the KPI.
2. **Follow linked evidence** — Traverse all reachable evidence links in priority order and continue while a source yields new actionable content.
3. **Map to service context** — Tie findings back to Azure SignalR Service, targetId `624c481d-e51c-4016-a522-fbe180d125fc`, known resource types, app names, and workflow names.
4. **Infer likely owner for concrete Azure resources when possible** — Use a deterministic, lightweight rule chain to annotate likely owners without overstating certainty.
5. **Synthesize concrete work items** — Translate raw findings into explicit statements of what the service team must do.
6. **Stop only on blockers** — Only stop when the next source requires auth, corpnet, unsupported tooling, or another hard blocker. Report that blocker precisely.

## Team Alias Map For Owner Inference

Use this map when inferring likely owners from Azure resource names, resource groups, or Azure metadata.

| Name | Alias |
|------|-------|
| Binjie Qian | `biqian` |
| Dayang Shen | `dayshen` |
| Haofan Liao | `haofanliao` |
| Jialin Xin | `jixin` |
| Jie Zong | `jiezong` |
| Ken Chen | `kenchen` |
| Kevin Guo | `kevinguo` |
| Liangying Wei | `lianwei` |
| Shiying Chen | `shiyingchen` |
| Siyuan Xing | `siyuanxing` |
| Siyuan Zheng | `siyzhe` |
| Yunchi Wang | `yunwang` |
| Zhenghui Yan | `zhy` |
| Zitong Yang | `zityang` |

Treat alias matching as case-insensitive. Normalize all candidate strings to lowercase before comparison.

## Workflow

### Step 1: Resolve Input

The user may provide:

| Input | How to handle |
|-------|--------------|
| KPI ID (UUID) | Use directly as `kpiId` |
| KPI action item ID | Use with `get_active_s360_action_item_for_kpi(kpiId, kpiActionItemId)` |
| Title text | Fetch all items via `search_active_s360_kpi_action_items`, then filter by `Title` match |
| S360 URL | Parse `kpiId` from URL path or query parameters |

If only a title is given, use `search_active_s360_kpi_action_items(targetIds=["624c481d-e51c-4016-a522-fbe180d125fc"], pageSize=50)` with pagination and filter results where `Title` contains or matches the user's text case-insensitively.

### Step 2: Fetch Items

For a KPI group:
- Fetch all items via `search_active_s360_kpi_action_items` with pagination.
- Filter to items matching the target `KpiId`.

For a single action item:
- Call `get_active_s360_action_item_for_kpi(kpiId, kpiActionItemId)` directly.

Collect enough raw payload detail to preserve all candidate evidence fields such as `URL`, `CustomDimensions.ActionWikiLink`, `CustomDimensions.url2`, `CustomDimensions.AssetTypeLink0`, `reportUrl`, and other URL-like fields.

### Step 3: Fetch KPI Metadata

Call `get_s360_kpi_metadata_by_kpi_id(kpiId)` to obtain:
- KPI description and remediation guidance
- Associated data sources such as dashboards, queries, and portals
- KPI category and program context
- Any embedded documentation links or workflow clues

Always inspect the metadata description text for remediation steps, workflow names, supportability hints, and embedded links.

### Step 4: Extract Affected Objects

Dispatch based on the data pattern observed in the action items.

| Signal in item data | Type | What is affected |
|---------------------|------|------------------|
| `CustomDimensions.resourceId` is a full ARM path | Type A | Individual Azure resources |
| `CustomDimensions.AssetTypeLink0` is an ADX dashboard URL | Type B | Aggregated infrastructure objects |
| `URL` contains Azure Resource Graph query | Type C | Queried infrastructure by subscription or region |
| `CustomDimensions.ApplicationId` with `reportUrl` | Type D | Applications and identities |
| Title or evidence indicates onboarding, ASP, ADO, compliance process, or workflow task | Type E | Workflow or process deliverables |
| None of the above | Unknown | Present all fields and infer pattern from evidence |

Read `references/resource-extraction-guide.md` for the detailed strategy per type.

### Step 4.5: Infer Resource Owner When The KPI Identifies Concrete Azure Resources

Apply this step when the investigation reveals a concrete Azure resource, especially for Type A items and Type C items that decode to explicit resources.

Use the following precedence exactly:

1. **Resource name match**
2. **Resource group match**
3. **Azure resource metadata match** via Azure MCP, Azure resource detail, or equivalent source by inspecting `systemData.createdBy`
4. **Leave owner blank** if none of the above yields a reliable match

Implementation rules:

- Compare against the alias map above first. Do not invent new owners.
- Resource name and resource group matching are intentionally lightweight. Match only on normalized whole-token or clear boundary-separated alias patterns such as `kevinguo`, `kevinguo-6215-resource`, `rg-lianweiai`, or `zhyan` when they clearly map back to one listed teammate.
- Do not use fragile substring guesses. For short aliases such as `zhy`, require a clean token or boundary-separated match rather than an arbitrary substring.
- If the resource name yields exactly one match, use it and do not override it with lower-priority sources.
- If the resource name has no match, inspect the resource group using the same rule.
- Only query Azure resource metadata when the first two steps fail.
- When using Azure metadata, inspect `systemData.createdBy` and normalize common forms such as alias, UPN prefix, or mail alias before matching to the alias map.
- If more than one teammate matches at the same priority level, leave owner blank and explicitly mark the owner as ambiguous rather than guessing.
- Always keep the evidence source with the owner annotation, for example `resourceName`, `resourceGroup`, or `systemData.createdBy`.
- Distinguish owner **confidence** from owner **precedence**. Resource name and resource group are heuristic; `systemData.createdBy` is metadata-backed. Even so, precedence remains the ordered rule chain above unless the higher-priority result is ambiguous.

### Step 5: Follow Evidence Links

After identifying the affected objects, follow all available evidence links in this priority order:

1. `item.URL`
2. Links embedded in KPI metadata description
3. `CustomDimensions.ActionWikiLink`
4. `CustomDimensions.url2`
5. `reportUrl`
6. `CustomDimensions.AssetTypeLink0`
7. Any other URL-bearing field in the payload

For each source:
- Fetch it when readable.
- If `fetch_webpage` fails, returns incomplete content, or appears to be blocked by rendering or auth flow, try the browser / Playwright MCP path before declaring a blocker.
- Extract concrete remediation steps, affected scope, ownership clues, environment information, and verification steps.
- Follow nested links when they add new actionable detail.
- Stop traversing a branch when it becomes redundant, circular, or no longer yields new evidence.

Browser fallback should be used especially for:
- Azure DevOps work item pages that render useful fields client-side
- ASP support docs that may not be captured well by static fetch
- Internal portals that redirect before showing readable content

Only declare a blocker after both direct fetch and browser-based inspection fail or still require unavailable credentials.

### Step 6: Correlate With Service Context

Ground the interpretation in repo-known service context:
- **Service name**: Azure SignalR Service
- **TargetId**: `624c481d-e51c-4016-a522-fbe180d125fc`
- **Known resource family**: `microsoft.signalrservice/signalr` and related service assets
- **Known workflow context**: previously saved S360 reports under `output/S360_Dashboard/` and service-specific wording found in linked evidence

Explicitly connect the findings to the service. Do not stop at generic KPI prose when the evidence points to a concrete Azure SignalR Service workflow, app, or asset.

If likely owners were identified for concrete Azure resources, connect those owners back to the service context carefully. Present them as operational routing hints, not authoritative service ownership, unless the source is explicit.

### Step 7: Ask the User Only After Readable Sources Are Exhausted

Only ask a targeted follow-up question if all readable sources have been exhausted and one narrow ambiguity still prevents a reliable explanation of the exact required work.

If the missing detail is caused by a hard blocker such as auth or corpnet, report the blocker instead of asking the user to restate the problem.

### Step 8: Render an Evidence-Chain Report

Use an evidence-oriented report that clearly separates verified findings, synthesis, remaining ambiguity, and blockers.

## Output Template

Structure the output as:

```markdown
## S360 Item Detail — {KPI Title}

**KPI ID**: {kpiId}
**SLA Status**: {worst SLAState across items} ({count} items)
**Due Date**: {earliest CurrentDueDate}
**Exceptions**: {total ExceptionCount}
**Clouds**: {distinct cloudType values}
**Type**: {Type A/B/C/D/E/Unknown}

### Summary
{1-2 sentences explaining what the service team must do}

### What This Task Is
{Explain the requirement, why the service is affected, and the scope backed by evidence}

### Evidence Reviewed
- {source and what it revealed}
- {source and what it revealed}

### Concrete Work Items
- {specific action item}
- {specific action item}

### Service-Specific Mapping
{Explain how the task maps to Azure SignalR Service resources, apps, workflows, or owners}

### Affected Resources / Affected Objects
{Type-specific content with explicit action wording}

### Open Questions / Ambiguities
- {only unresolved items after evidence review}

### Blockers
- **Source**: {URL or source name}
	**Blocker Type**: {auth, corpnet, unsupported tool, dead link}
	**Access Needed**: {what the user or owner would need}

### Next Steps
1. {highest-priority next step}
2. {follow-up step}
3. {escalation or verification step}
```

### Type-Specific Expectations

**Type A**
- Show each resource and state the concrete remediation action for that resource.
- When possible, annotate each resource with a likely owner, owner evidence source, and owner confidence.

Example columns:

```markdown
| Resource ID | Subscription | Resource Group | Likely Owner | Owner Evidence | Owner Confidence | Action Required | SLA Status | Due Date |
|-------------|--------------|----------------|--------------|----------------|------------------|-----------------|------------|----------|
```

**Type B**
- Explain what the aggregated dashboard represents and what action must be taken on the affected asset class.

**Type C**
- Decode the ARG query, explain what condition it is identifying, and state what configuration must change.

**Type D**
- Explain what the application or identity is missing and what compliance or onboarding action is required.

**Type E**
- Focus on deliverables such as onboarding steps, ADO work items, documentation fixes, diagnostics updates, or checklist completion. These are not resource-remediation KPIs and should not be forced into a resource table if the evidence points to workflow work.

## Quick Reference

| Situation | Action |
|-----------|--------|
| User gives a KPI ID | Fetch items, extract objects, follow evidence links, synthesize work items |
| User gives a title | Search by title, then run the same investigation flow |
| User asks what work must be done | Emphasize `Concrete Work Items` and `Service-Specific Mapping` |
| KPI is process or onboarding oriented | Treat work item pages, docs, and checklists as primary evidence |
| Evidence remains ambiguous | Ask one targeted question only after readable sources are exhausted |
| Next source is inaccessible | Report an explicit blocker with the required access |

## Important Notes

- Investigation is multi-hop by default. A shallow summary of the S360 payload is not sufficient when linked evidence exists.
- Distinguish **verified evidence** from **inference**. Make it clear which statements came from accessible sources and which are reasoned synthesis.
- Prefer synthesis over dumping links. The goal is to explain what the service team must do, not merely where more information might exist.
- When static fetch is insufficient, use browser-based inspection before concluding a page is blocked. A blocker should reflect the strongest attempt actually made.
- If a source cannot be read, report it as a blocker with exact access guidance rather than quietly stopping.
- Keep the analysis grounded to Azure SignalR Service context whenever the evidence allows it.
- Likely owner annotations are for routing and investigation acceleration. They are not authoritative ownership claims unless backed by explicit metadata or a directly readable source.
