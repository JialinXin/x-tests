# ICM Weekly Draft Configuration

## Verified Defaults

Use these values unless the user explicitly overrides them.

| Field | Value |
| --- | --- |
| Service Name | Azure SignalR Service |
| Owning Service ID | `23656` |
| Owning Team Name | Triage |
| Owning Team ID | `44302` |
| Output Directory | `Tasks/ICM_Weekly/` |

These values were verified from live ICM samples for Azure SignalR Service triage incidents.

## Primary Retrieval Method

Fetch by owning team first:

```text
mcp_icm_mcp_serve_search_incidents_by_owning_team_id({ teamId: 44302 })
```

Then filter locally by:
- `owningServiceId == 23656`
- target UTC week

This is safer than assuming a direct service-filtered search exists.

## Time Window Policy

Default report window is the **previous full UTC week**.

Definition:
- start = previous Monday `00:00:00.000Z`
- end = previous Sunday `23:59:59.999Z`

Preferred event timestamp for table rows:
1. `impactStartTime`
2. `createdDate`

## Useful Incident Fields

Observed as reliably useful from ICM detail payloads:
- `id`
- `title`
- `severity`
- `state`
- `createdDate`
- `impactStartTime`
- `lastModifiedDate`
- `hitCount`
- `isCustomerImpacting`
- `owningTenantName`
- `owningTeamName`
- `tsgLink`
- `mitigateData.mitigateTime`
- `mitigateData.mitigatedBy`
- `occuringLocation`

Treat these as opportunistic rather than guaranteed:
- AI summary
- incident context
- mitigation hints
- similar incidents
- support request context

## ICM Link Pattern

Use the standard incident link form:

```text
https://portal.microsofticm.com/imp/v3/incidents/details/{incidentId}/home
```

Prefer showing the link on the title text, for example:

```markdown
[Incident 745248815: [TableErrors] Table requests has continuous failures of Timeout](https://portal.microsofticm.com/imp/v3/incidents/details/745248815/home)
```