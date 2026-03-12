# Resource Extraction Guide

Per-KPI-type strategies for extracting Azure ResourceIds and related information from S360 action items.

## TSG / Remediation Doc Sources

TSG (Troubleshooting Guide) links come from multiple places — check all of them:

1. **`URL` field** on the action item — most commonly an eng.ms link (e.g., `https://eng.ms/docs/...`)
2. **KPI metadata description** — call `get_s360_kpi_metadata_by_kpi_id(kpiId)` and check the description text for embedded links
3. **Kusto dashboard descriptions** — some KPIs link to ADX dashboards that include TSG references in their panel descriptions
4. **`CustomDimensions.ActionWikiLink`** — wiki-based remediation guide (e.g., `https://aka.ms/VulnerabilityAction-...`)
5. **`CustomDimensions.url2`** — some items carry a secondary URL that points to documentation

Always present any eng.ms link prominently as the primary remediation reference.

## Type Classification

When you receive action items for a KPI, look at these fields to determine the type:

```
1. Check CustomDimensions.resourceId → if present and is a full ARM path → Type A
2. Check CustomDimensions.AssetTypeLink0 → if present and points to ADX dashboard → Type B
3. Check URL → if contains "portal.azure.com" + "ArgExplorer" → Type C
4. Check CustomDimensions.ApplicationId → if present with reportUrl → Type D
5. Otherwise → Unknown (present raw data)
```

Multiple signals can coexist. Prioritize: Type A > Type B > Type C > Type D (prefer the most specific resource info).

---

## Type A: Direct ResourceId

**Identifying signal**: `CustomDimensions.resourceId` is a full ARM resource path like `/subscriptions/{sub}/resourcegroups/{rg}/providers/{provider}/{type}/{name}`

**Example KPI**: "Disable local auth for microsoft.signalrservice/signalr" (KPI ID: `6b5bc0b6-3027-481d-991a-5944155ba2c8`)

**Extraction**:
```
For each item:
  resourceId = item.CustomDimensions.resourceId
  Parse ARM path to extract:
    subscriptionId = segment after /subscriptions/
    resourceGroup = segment after /resourcegroups/
    resourceType = provider/type (e.g., microsoft.signalrservice/signalr)
    resourceName = last segment
```

**Real example from API**:
```json
{
  "Title": "Disable local auth for microsoft.signalrservice/signalr",
  "SLAState": "InSla",
  "CurrentDueDate": "2026-06-29T00:00:00Z",
  "CustomDimensions": {
    "resourceId": "/subscriptions/9caf2a1e-9c49-49b6-89a2-56bdec7e3f97/resourcegroups/myresourcegroup/providers/microsoft.signalrservice/signalr/mysignalrname",
    "resourceType": "microsoft.signalrservice/signalr",
    "issueType": "resource local auth enabled",
    "cloudType": "Public",
    "tenantId": "72f988bf-86f1-41af-91ab-2d7cd011db47"
  }
}
```

**Notes**:
- Each item represents one resource. A KPI group can have 50+ items, each with a different `resourceId`.
- Also check `CustomDimensions.tenantId` and `CustomDimensions.SubType` for environment classification (e.g., `microsoft.signalrservice/signalr~nonprod`).
- The `URL` field for these items typically points to a TSG doc (e.g., `https://eng.ms/docs/...`), not to the resource itself.

---

## Type B: Aggregated Dashboard (ADX)

**Identifying signal**: `CustomDimensions.AssetTypeLink0` contains an Azure Data Explorer dashboard URL (`dataexplorer.azure.com/dashboards/...`)

**Example KPIs**: 
- "Remove EOL Software On Container Image" (KPI ID: `527fb616-07aa-8198-6419-50d04ef1c2f3`)
- "Update Vulnerable Container Image Reference"

**Extraction**:
```
Key fields:
  totalCount = item.CustomDimensions.TotalCount
  assetType = item.CustomDimensions.AssetType0 (e.g., "Container Host (385680)")
  dashboardUrl = item.CustomDimensions.AssetTypeLink0
  actionWikiLink = item.CustomDimensions.ActionWikiLink
  sla = item.CustomDimensions.SLA (e.g., "Past SLA", "Near SLA")
  environments = item.CustomDimensions.Environments (e.g., "PPE", "PPE, Prod")
  clouds = item.CustomDimensions.Clouds

No per-resource ARM ResourceId — resources are aggregated in the ADX dashboard.
```

**Real example from API**:
```json
{
  "Title": "Remove EOL Software On Container Image",
  "SLAState": "OutOfSla",
  "CurrentDueDate": "2025-06-09T00:00:00Z",
  "CustomDimensions": {
    "TotalCount": 6,
    "AssetTypes": "Container Host",
    "AssetType0": "Container Host (6)",
    "AssetTypeLink0": "https://dataexplorer.azure.com/dashboards/48834d42-391b-479d-a0fd-b748d939626b?p-_Filter_RemediationOwner=624c481d-...",
    "ActionWikiLink": "https://aka.ms/VulnerabilityAction-RemoveEOLSoftwareOnContainerImage",
    "SLA": "Past SLA",
    "Environments": "PPE",
    "Clouds": "Public"
  }
}
```

**Optional Kusto deep-dive**: The ADX dashboard URL contains filter parameters. If the user wants the actual resource list:
1. Navigate to the dashboard link to see the filtered view
2. If Kusto cluster/database info can be extracted from the URL, try executing a query via `mcp_kusto_execute_query`
3. The dashboard ID `48834d42-391b-479d-a0fd-b748d939626b` is the ADX dashboard — you may not have direct query access

**When Kusto is not accessible**: Provide the dashboard link and mention that the user needs access to the ADX dashboard. Link to the `ActionWikiLink` for remediation steps.

---

## Type C: Azure Resource Graph Query

**Identifying signal**: `URL` field contains `ms.portal.azure.com/#view/Microsoft_Azure_Resources/ArgExplorer` with an embedded query

**Example KPI**: "Service has Subnets with Default Outbound Access" (KPI ID: `5c85fca2-d174-492c-80df-4cdaa5f74b4d`)

**Extraction**:
```
Key fields:
  subscriptionId = item.CustomDimensions.SubscriptionId
  region = item.CustomDimensions.Region
  itemsToMitigate = item.CustomDimensions.ItemsToMitigate
  totalVNetsToMitigate = item.CustomDimensions.TotalVNetsToMitigate
  divisionName = item.CustomDimensions.DivisionName
  argQueryUrl = item.URL

Decode the ARG query from the URL:
  1. Extract the "query" parameter value from the URL
  2. URL-decode: %0D%0A → \n, %7C → |, %3D → =, etc.
  3. Present the decoded KQL query
```

**Real example from API**:
```json
{
  "Title": "Service has Subnets with Default Outbound Access",
  "SLAState": "InSla",
  "CurrentDueDate": "2026-03-31T00:00:00Z",
  "CustomDimensions": {
    "ActionItemSubtype": "Wave8DefaultOutboundAccess",
    "DivisionName": "CoreAI",
    "Region": "southeastasia",
    "SubscriptionId": "9caf2a1e-9c49-49b6-89a2-56bdec7e3f97",
    "ItemsToMitigate": 23,
    "TotalVNetsToMitigate": 17,
    "url2": "https://eng.ms/docs/cloud-ai-platform/..."
  },
  "URL": "https://ms.portal.azure.com/#view/Microsoft_Azure_Resources/ArgExplorer.ReactView/query/Resources%0D%0A%7C%20where%20type%20%3D~%20%22microsoft.network%2Fvirtualnetworks%22..."
}
```

**Decoded ARG query** (from the URL above):
```kusto
Resources
| where type =~ "microsoft.network/virtualnetworks"
| where subscriptionId == "0894a282-3fb9-4e45-b3a6-ab38ec5414e6"
| mv-expand defaultOutboundConnectivityEnabled = properties.defaultOutboundConnectivityEnabled
| extend subnets=todynamic(properties["subnets"])
| mv-expand subnets
| extend subnetId = tostring(subnets.id)
| summarize hint.strategy=shuffle make_list_if(subnetId, subnets.properties.defaultOutboundAccess!=false) by id, location
| where array_length(list_subnetId) >= 1
| project vnetid = id, CountOfSubnets=array_length(list_subnetId), tostring(list_subnetId), location
```

**Note**: The subscriptionId in the URL query may differ from `CustomDimensions.SubscriptionId` — the URL query is pre-filtered. Present both the item-level SubscriptionId and the decoded query.

---

## Type D: App-Based

**Identifying signal**: `CustomDimensions.ApplicationId` is present along with `reportUrl`, `AppName`, `ReasonFlagged`

**Example KPI**: "MISE Compliance - 1.31.0+ [Wave 8]" (KPI ID: `f05752b5-8212-459a-a0ed-41f52ee47664`)

**Extraction**:
```
Key fields:
  applicationId = item.CustomDimensions.ApplicationId
  appName = item.CustomDimensions.AppName
  reasonFlagged = item.CustomDimensions.ReasonFlagged
  reportUrl = item.CustomDimensions.reportUrl
  platform = item.CustomDimensions.platform
  miseVersion = item.CustomDimensions.MiseVersion
  cloudType = item.CustomDimensions.cloudType
```

**Real example from API**:
```json
{
  "Title": "MISE Compliance - 1.31.0+ [Wave 8]",
  "SLAState": "InSla",
  "CurrentDueDate": "2026-06-30T00:00:00Z",
  "CustomDimensions": {
    "ApplicationId": "908d9a80-0d7d-44c6-afec-a4589e4b8d16",
    "AppName": "Azure SignalR Service Live Trace Tool",
    "ReasonFlagged": "On 03/02/26, 2 token(s) were acquired for this app ID but no MISE/SAL key discovery (server) telemetry was present...",
    "platform": "eSTS",
    "reportUrl": "https://aka.ms/mise/servicehealth?filter=ServiceTreeData/ServiceId eq '624c481d-e51c-4016-a522-fbe180d125fc'",
    "cloudType": "Fairfax"
  },
  "URL": "https://aka.ms/mise/kpi-tsg"
}
```

**No ARM ResourceId** — MISE compliance tracks AAD applications, not ARM resources. Present the application details and link to the MISE service health report.

---

## Unknown Type (Fallback)

If an item doesn't match any of the above patterns:

1. Present all `CustomDimensions` fields in a key-value table
2. Show the `URL` and any links in S360Dimensions
3. Note which fields are present so the user can identify the pattern
4. Suggest checking the KPI metadata via `get_s360_kpi_metadata_by_kpi_id(kpiId)` for more context

---

## Handling Multiple Items per KPI

When a KPI has many items (e.g., 50+ "Disable local auth" items):

- **Type A**: List all resourceIds in a table. If there are > 30, consider grouping by subscription or resource group and showing counts, with the full list available in the saved file.
- **Type B**: Usually one aggregated item per unique combination of (action, SLA, cloud). Show each as a separate entry with its dashboard link.
- **Type C**: Usually one item per (subscription, region) combination. Show each with its ARG query link.
- **Type D**: Usually one item per application. Show each app in the table.

## Permission and Access Notes

When a linked resource is not accessible, provide guidance:

| Resource Type | Access Needed |
|---------------|---------------|
| ADX Dashboard (`dataexplorer.azure.com/dashboards/...`) | Azure Data Explorer viewer role on the dashboard |
| Azure Portal ARG Explorer | Reader role on the target subscription |
| eng.ms docs | Microsoft corpnet or VPN access |
| MISE Service Health (`aka.ms/mise/servicehealth`) | MISE portal access — request via https://aka.ms/mise |
| Azure Subscription resources | Reader / Contributor role on the subscription |
