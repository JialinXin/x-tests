# S360 FIPS Workflow

## Purpose
- Identify Azure SignalR Service nodes missing FIPS (Federal Information Processing Standards) compliance.
- Generate GenevaActions batch input to remediate targeted virtual machines.
- Provide repeatable execution steps and output expectations for each assessment run.

## Prerequisites
- Work with MCP Tool: azmcp-kusto-query to execute kusto query, based on a known Kusto cluster: https://signalrinsights.eastus2.kusto.windows.net, Database: SignalRBI and SubscriptionId: 5f4ae1cc-5bfe-4be0-b94d-6e0bf198c74b.
- GenevaActions permissions to submit remediation batches.
- Up-to-date service metadata: Detail table name, service name, and service object ID.
- Local tooling capable of converting VM scale set instance IDs from decimal to base-36 in Azure-compliant format.

## Roles
- **Request Owner**: Confirms scope (subscriptions, regions) and desired remediation window.
- **Task Lead**: Coordinates execution, validates data transformations, and signs off on results.
- **Execution Analyst**: Runs Kusto queries, performs data shaping, and prepares GenevaActions payloads.

## Standard Flow
| Step | Description | Responsible | Inputs | Outputs |
| --- | --- | --- | --- | --- |
| Intake | Validate scope, SLAs, and remediation goals. | Request Owner, Task Lead | Request brief, subscription list | Agreed success criteria, timeline |
| Plan | Confirm table names, parameters, and tooling readiness. | Task Lead | Service metadata, tooling checklist | Execution plan, parameter sheet |
| Prepare | Stage query environment and test base-36 converter. | Execution Analyst | Kusto access, transformation script | Ready workspace, verified helper tools |
| Execute | Run Kusto query and export flagged nodes. | Execution Analyst | Query definition, service identifiers | Ordered VM list with core metadata |
| Transform | Convert query output into GenevaActions format. | Execution Analyst | Query results | `ACSCluster,AgentNodeName` batch file |
| Assess | Sanity-check payload, spot anomalies, confirm coverage. | Task Lead | Batch file, original results | Validation notes, remediation recommendations |
| Report | Share outputs, archive artifacts, assign follow-up. | Task Lead, Request Owner | Validation notes | Final report, action tracker |

## Detailed Execution Steps
1. **Run Kusto query** to enumerate VMs missing FIPS compliance:
	 ```kusto
	 let _DivisionName = '';
	 let _OrganizationName = dynamic(null);
	 let _ServiceGroupName = dynamic(null);
	 let _ServiceTreeId = dynamic(['624c481d-e51c-4016-a522-fbe180d125fc']);
	 let _TeamGroupName = dynamic(null);
	 set norequesttimeout;
	 set notruncation;
	 cluster('agesconmonadx.westus2.kusto.windows.net').database('conmon').FedRAMP_Services_FullData
	 | project  DivisionName, OrganizationName, ServiceGroupName, TeamGroupName, ServiceTreeName, ServiceTreeId
	 | order by DivisionName, OrganizationName, ServiceGroupName, TeamGroupName, ServiceTreeName asc
	 | join kind=fullouter (
	 cluster('agesconmonadx.westus2.kusto.windows.net').database('conmon').OSFamily_Data_PROD
	 | where Source !contains "container"
	 | where InFedRAMPCurrent ==1 or InFedRAMPFuture ==1
	 | lookup cluster('agesconmonadx.westus2.kusto.windows.net').database('conmon').OSlookup on OS
	 | where FIPSEnabled==false
	 //| where OSBasic !startswith "WS" and OSBasic !startswith "W1" and OSBasic !='Empty'
	 | project FIPSEnabled, FIPSEnabledSource, AssetId, OSBasic,Release, ServiceTreeName, ServiceTreeId, AssetType, SubscriptionId, SubscriptionName, Region, ResourceGroup, VMScaleSetName, RoleName, TenantName, TenantId, ClusterName, EnvironmentName, MachineFunction, InFedRAMPCurrent, InFedRAMPFuture
	 ) on ServiceTreeId
	 | where isempty(['_DivisionName']) or DivisionName  in (['_DivisionName'])
	 | where isempty(['_OrganizationName']) or OrganizationName in (['_OrganizationName'])
	 | where isempty(['_ServiceGroupName']) or ServiceGroupName in (['_ServiceGroupName'])
	 | where isempty(['_TeamGroupName']) or TeamGroupName in (['_TeamGroupName'])
	 | where isempty(['_ServiceTreeId']) or ServiceTreeId in (['_ServiceTreeId'])
	 | project-away ServiceTreeId1, ServiceTreeName1
	 | order by DivisionName asc , OrganizationName asc, ServiceGroupName asc, TeamGroupName asc, ServiceGroupName asc, ServiceGroupName asc
	 | join kind=leftouter (cluster('agesconmonadx.westus2.kusto.windows.net').database('conmon').OSFamily_Data_PROD_NonContainersPreLoad_yesterday 
	     | project AssetId
	     | extend AssetExistedYesterday=1
	     ) on AssetId
	 | project-away AssetId1
	 | project-reorder AssetExistedYesterday
	 | join kind=leftouter cluster('agesconmonadx.westus2.kusto.windows.net').database('conmon').OSFamily_FIPSEnabledState on AssetId
	 //| where not(FIPSEnabled)
	 | distinct SubscriptionId, SubscriptionName, Region, ResourceGroup = tolower(ResourceGroup), RoleName
     | order by Region asc, RoleName asc
	 ```
2. **Export the query results** to a structured file (CSV or Markdown table) and store it with the run log.
3. **Transform fields** to GenevaActions batch parameters:
	 - `ACSCluster`: Concatenate `SubscriptionId` and `ResourceGroup` without separators (example: `720cfcbe-dd20-4df4-85b0-221e7f17a569srprodacsaueb`).
	 - `AgentNodeName`: Convert `RoleName` to the Geneva agent format by translating the numeric suffix from base-10 to base-36 while preserving Azure VM naming rules (example: `k8s-ingress-000008-z2-vmss_35` → `k8s-ingress-000008-z2-vmss00000Z`).
4. **Validate the payload** for duplicates, malformed names, or unsupported regions before remediation.

## Output Expectations
- **Execution Result** (retain in the run log):
	| SubscriptionId | SubscriptionName | Region | ResourceGroup | RoleName |
	| --- | --- | --- | --- | --- |
	| ... | ... | ... | ... | ... |

- **Final Result** (GenevaActions batch file):
	```text
	ACSCluster,AgentNodeName
	...,...
	...,...
	```

## Recording Results
- Create a run result named `yyyyMMddfff.md` (`fff` = milliseconds, UTC) in `Tasks/S360_FIPS/` after each execution for the exptected output only.
- Create a run log named `yyyyMMddfff.txt` to capture execution steps: Summary, Executed Steps, Status(Success or Failure reason like exceptions), 
- Treat run logs as immutable; add new timestamped files for reruns or corrections.

## Evidence Management
- Store raw query exports, transformation worksheets, and submission receipts in the agreed repository; reference their paths in the run log.
- Note any exceptions or manual adjustments made during transformation.

## Escalation
- Escalate access issues or Kusto query failures to the service owner within one business day.
- If transformation logic fails, notify the Task Lead and pause remediation until the script is fixed.

## Post-Run Checklist
- Notify stakeholders with the final report and GenevaActions payload.
- Update tracking systems or tickets with references to the run log and remediation status.
- Schedule follow-up validation once GenevaActions completes to verify FIPS compliance.