# Resource Extraction Guide

Per-KPI-type strategies for extracting affected resources or objects and interpreting what work must be done for an S360 action item.

## Investigation Depth Policy

Use this guide as an evidence-gathering policy, not just a field parser.

1. **Follow evidence by default** — Continue through reachable evidence links until the task is clearly explained or a hard blocker is hit.
2. **Separate evidence from inference** — Report what was directly observed versus what was inferred from context.
3. **Ground interpretation in service context** — Prefer explanations tied to Azure SignalR Service, its targetId, known resource families, apps, and workflow names.
4. **Ask the user only after exhausting readable sources** — Questions should be narrow and only used to resolve the final ambiguity.
5. **Try browser fallback before blocking** — If static fetch is incomplete or blocked, use browser / Playwright-style MCP tools to inspect rendered content, redirects, and interactive pages.
6. **Treat inaccessible sources as blockers** — Do not stop with a vague best-effort note. Record the blocked source, reason, and required access.
7. **Annotate likely owners conservatively** — For concrete Azure resources, enrich the report with a likely owner only when it matches the defined rule chain and evidence can be named.

## Service Context Grounding

For this repo, the default service context is:

- **Service Name**: Azure SignalR Service
- **TargetId**: `624c481d-e51c-4016-a522-fbe180d125fc`
- **Common resource family**: `microsoft.signalrservice/signalr`

When evidence mentions service names, app names, onboarding workflow names, or resource types, explicitly connect them back to Azure SignalR Service instead of leaving them as generic KPI commentary.

## TSG / Remediation Doc Sources

TSG and remediation links can come from multiple places. Check all of them and continue recursively when a linked page reveals additional actionable detail.

1. **`URL` field** on the action item — often an eng.ms link, dashboard, ARG query, or portal page
2. **KPI metadata description** — inspect for embedded links, checklist items, workflow names, or remediation statements
3. **Kusto dashboard descriptions** — some dashboards contain links to remediation docs or explain affected scope
4. **`CustomDimensions.ActionWikiLink`** — wiki-style remediation guide
5. **`CustomDimensions.url2`** — secondary documentation source
6. **`reportUrl`** or similar fields — portal, MISE, or service health views
7. **Other URL-bearing fields** — do not ignore them if they may clarify required work

Always surface any eng.ms link prominently when it is accessible, but do not stop at the first link if that page points to more specific remediation content.

When a source is only partially available through static fetch, try browser-based inspection before treating it as blocked. This is especially important for Azure DevOps pages, support portals, and docs that render content client-side.

## Type Classification

When you receive action items for a KPI, inspect these signals first:

```text
1. Check CustomDimensions.resourceId -> if present and is a full ARM path -> Type A
2. Check CustomDimensions.AssetTypeLink0 -> if present and points to ADX dashboard -> Type B
3. Check URL -> if contains portal.azure.com + ArgExplorer -> Type C
4. Check CustomDimensions.ApplicationId -> if present with reportUrl -> Type D
5. Check title and evidence for onboarding, ASP, work item, process, checklist, or supportability cues -> Type E
6. Otherwise -> Unknown
```

Multiple signals can coexist. Prefer the most specific object-level signal first, but keep workflow clues if they explain the actual required work better than the raw object field alone.

## Resource Owner Inference For Azure Resources

Use this section only when the KPI investigation reaches concrete Azure resources.

### Alias Map

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
| Zhenghui Yan | `zhyan` |
| Zitong Yang | `zityang` |

### Precedence Rules

Apply the owner lookup in this order and stop at the first unambiguous match:

1. `resourceName`
2. `resourceGroup`
3. Azure resource metadata such as `systemData.createdBy`
4. blank owner

### Matching Rules

Normalize candidate values to lowercase.

Prefer exact token or boundary-separated matches such as:

- `kevinguo`
- `kevinguo-6215-resource`
- `rg-lianweiai`
- `jixin-test`

Avoid arbitrary substring matches that can create false positives. For short aliases like `zhy`, require a clean token boundary.

Treat owner inference as follows:

- `resourceName` match => `confidence = heuristic-high`
- `resourceGroup` match => `confidence = heuristic-medium`
- `systemData.createdBy` match => `confidence = metadata`
- no unambiguous match => leave owner blank

If multiple teammates match at the same precedence level, set owner to blank and record the result as ambiguous.

### Metadata Fallback Guidance

If `resourceName` and `resourceGroup` do not match, try an Azure detail source when available.

Check fields such as:

- `systemData.createdBy`
- `systemData.lastModifiedBy` only as supplemental context, not as the primary owner signal
- resource tags only if a clearly owner-like tag exists and the main rule chain still produced no result

When `systemData.createdBy` is present, normalize common forms before matching:

- alias only, such as `jixin`
- UPN, such as `jixin@microsoft.com`
- mail alias with domain variants

Do not override a higher-priority unambiguous name-based match with metadata. The precedence order is intentional for lightweight routing.

### Output Guidance

For resource-oriented reports, add owner-related fields when they can be inferred:

```markdown
| Resource ID | Resource Group | Resource Name | Likely Owner | Owner Evidence | Owner Confidence | Action Required |
|-------------|----------------|---------------|--------------|----------------|------------------|-----------------|
```

If owner is blank, keep the column blank or use `Unknown` only when the report benefits from an explicit placeholder. Do not invent fallback owners.

## Type A: Direct ResourceId

**Identifying signal**: `CustomDimensions.resourceId` is a full ARM path such as `/subscriptions/{sub}/resourcegroups/{rg}/providers/{provider}/{type}/{name}`.

**Example KPI**: `Disable local auth for microsoft.signalrservice/signalr`.

**Extraction**:

```text
For each item:
  resourceId = item.CustomDimensions.resourceId
  Parse ARM path to extract:
    subscriptionId
    resourceGroup
    resourceType
    resourceName
  Infer likely owner using the owner rule chain:
    1. resourceName
    2. resourceGroup
    3. systemData.createdBy
    4. blank
```

**Investigation focus**:
- Identify the exact non-compliant state.
- Follow the TSG or linked documentation to determine the precise configuration change.
- Translate the result into per-resource action wording.
- When possible, attach likely owner, owner evidence, and owner confidence for routing.

**Notes**:
- A KPI group can contain many resources.
- `URL` usually points to the remediation guide, not the resource itself.
- Check `tenantId`, `SubType`, and environment hints for rollout planning.

## Type B: Aggregated Dashboard (ADX)

**Identifying signal**: `CustomDimensions.AssetTypeLink0` contains an Azure Data Explorer dashboard URL.

**Examples**:
- `Remove EOL Software On Container Image`
- `Update Vulnerable Container Image Reference`

**Extraction**:

```text
Key fields:
  totalCount = item.CustomDimensions.TotalCount
  assetType = item.CustomDimensions.AssetType0
  dashboardUrl = item.CustomDimensions.AssetTypeLink0
  actionWikiLink = item.CustomDimensions.ActionWikiLink
  environments = item.CustomDimensions.Environments
  clouds = item.CustomDimensions.Clouds
```

**Investigation focus**:
- Explain what the dashboard is aggregating.
- Follow the remediation wiki and dashboard context to determine what change must be made to the affected asset class.
- If possible, extract enough detail to describe who or what needs remediation, even when per-resource ARM IDs are unavailable.

**When Kusto is inaccessible**:
- Report the ADX dashboard as a blocker only for the missing detail that requires it.
- Still synthesize the remediation requirement from accessible wiki or metadata sources.

## Type C: Azure Resource Graph Query

**Identifying signal**: `URL` contains an Azure Portal Resource Graph Explorer link with an embedded query.

**Example KPI**: `Service has Subnets with Default Outbound Access`.

**Extraction**:

```text
Key fields:
  subscriptionId = item.CustomDimensions.SubscriptionId
  region = item.CustomDimensions.Region
  itemsToMitigate = item.CustomDimensions.ItemsToMitigate
  totalVNetsToMitigate = item.CustomDimensions.TotalVNetsToMitigate
  argQueryUrl = item.URL
```

Decode the query and explain:
- What condition the query is looking for
- Why that condition is non-compliant
- What configuration must change to become compliant

Present both the decoded query and the plain-language remediation interpretation.

## Type D: App-Based

**Identifying signal**: `CustomDimensions.ApplicationId` is present with `reportUrl`, `AppName`, or `ReasonFlagged`.

**Example KPI**: `MISE Compliance - 1.31.0+ [Wave 8]`.

**Investigation focus**:
- Treat the affected object as an application or service identity, not an ARM resource.
- Follow the report link and related docs to determine the exact onboarding or compliance gap.
- Explain what the service team must do for the app or identity.

Do not force these into a resource-centric explanation when the evidence is clearly about app telemetry, discovery, or policy compliance.

## Type E: Workflow / Process KPI

**Identifying signal**: Evidence points to work items, ASP onboarding, supportability scenarios, compliance checklists, article maintenance, diagnostics onboarding, or other process tasks.

**Common examples**:
- ADO work item links
- ASP onboarding tasks
- Supportability scenario onboarding
- Documentation or CRC maintenance requirements
- Process or compliance follow-up items that do not map to ARM resources

**Investigation focus**:
- Treat work item pages, onboarding docs, and checklists as the primary evidence chain.
- Identify the real deliverables, such as article updates, diagnostics fixes, metadata corrections, or checklist completion.
- Explain how those deliverables map back to Azure SignalR Service workflows or owners.
- If a work item or onboarding doc appears blocked in static fetch, try browser inspection before concluding that the detail is unavailable.

**Output guidance**:
- Do not pretend these are resource-remediation KPIs.
- Prefer a `Concrete Work Items` section over a resource table when the task is workflow-oriented.
- Call out missing evidence from inaccessible ADO or internal pages as explicit blockers.

## Unknown Type (Fallback)

If an item does not cleanly match Types A-E:

1. Present all `CustomDimensions` fields in a key-value view.
2. List every reachable link and what it revealed.
3. Note which signals are present.
4. Use metadata plus service context to infer the most likely task.
5. If a final ambiguity remains after reading all accessible sources, ask one targeted user question or report a blocker.

## Handling Multiple Items per KPI

When a KPI has many items:

- **Type A**: Group by subscription, resource group, or action type when the list is large, but keep the saved report actionable.
- **Type B**: Show each aggregated bucket and explain the remediation requirement per bucket.
- **Type C**: Group by subscription and region, then explain the configuration change each query is identifying.
- **Type D**: Show each app or identity and its required onboarding or compliance action.
- **Type E**: Group by deliverable, workflow owner, or checklist stage rather than by pseudo-resource.

## Permission and Access Notes

When a linked resource is not accessible, report it as a blocker with access guidance.

| Resource Type | Access Needed |
|---------------|---------------|
| ADX Dashboard (`dataexplorer.azure.com/dashboards/...`) | Azure Data Explorer viewer role on the dashboard |
| Azure Portal ARG Explorer | Reader role on the target subscription |
| eng.ms docs | Microsoft corpnet or VPN access |
| MISE Service Health (`aka.ms/mise/servicehealth`) | MISE portal access |
| Azure DevOps work item or internal doc | Appropriate ADO project access or corpnet-backed auth |
| Azure Subscription resources | Reader or Contributor role on the subscription |

Do not downgrade these to vague best-effort notes. State which source was blocked, why it was blocked, what retrieval attempts were made, and what access is required to continue.
