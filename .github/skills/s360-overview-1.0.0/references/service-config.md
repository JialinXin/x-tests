# Service Configuration

## Target Service

| Field | Value |
|-------|-------|
| Service Name | Azure SignalR Service |
| Service Tree ID (targetId) | `624c481d-e51c-4016-a522-fbe180d125fc` |
| Team | kenchen_team |

## S360 Dashboard URL

People-scoped dashboard (overview in browser):
```
https://vnext.s360.msftcloudes.com/blades/allup?peopleBasedNodes=kenchen_team&blade=Tab:KPI~isExpanded:false~KPIType:ActionItems;LaunchCriteria;Metric~_loc:allUp&global=@KENCHEN%2BKen%20Chen%20(KENCHEN)
```

## API Configuration

The S360-breeze MCP tool uses `targetIds` (service tree IDs), not the people-scoped URL. Pass the targetId above as:

```json
{
  "targetIds": ["624c481d-e51c-4016-a522-fbe180d125fc"],
  "pageSize": 50
}
```

## Known KPI IDs

These are KPI IDs observed in the service's action items. Use them for quick filtering or detail lookups.

| KPI ID | Title | Type | Resource Extraction Strategy |
|--------|-------|------|------------------------------|
| `6b5bc0b6-3027-481d-991a-5944155ba2c8` | Disable local auth | Type A | Direct `CustomDimensions.resourceId` |
| `5c85fca2-d174-492c-80df-4cdaa5f74b4d` | Subnets with Default Outbound Access | Type C | Azure Resource Graph query in `URL` |
| `527fb616-07aa-8198-6419-50d04ef1c2f3` | Container Image vulnerabilities | Type B | `AssetTypeLink0` → ADX dashboard |
| `f05752b5-8212-459a-a0ed-41f52ee47664` | MISE Compliance | Type D | `ApplicationId` + `reportUrl` |

New KPIs will appear as S360 data changes. The extraction strategies above are starting points — see `s360-item-detail` skill's `references/resource-extraction-guide.md` for the full guide.

## Output Directory

All generated reports are saved to: `Tasks/S360_Dashboard/`
