# S360 Security Pack Workflow

## Purpose
- Identify Azure SignalR Service nodes missing the Azure Security Pack (AzSecPack) deployment.
- Generate GenevaActions batch input to remediate targeted virtual machines.
- Provide repeatable execution steps and output expectations for each assessment run.

## Prerequisites
- Work with Azure Kusto MCP, Kusto cluster: https://azsecslamfollower.westus2.kusto.windows.net, Database: AsmKPIAlertDB.
- Up-to-date service metadata: Detail table name, service name, and service object ID.
- Local tooling capable of converting VM scale set instance IDs from decimal to base-36 in Azure-compliant format.

## Critical Execution Rules
> **⚠️ IMPORTANT: These rules MUST be strictly enforced during all workflow executions.**

1. **No Mock Data**: Never create, fabricate, or simulate data manually. All data must originate from actual Kusto query results.
2. **Fail-Fast Principle**: If any step fails (Kusto query failure, MCP connection error, script execution error, etc.), STOP immediately, log the error, and report to the user.
3. **No Validation Bypass**: Never skip data validation steps or proceed with unverified data.
4. **Authentic Data Sources Only**: All CSV files must be directly exported from Kusto queries. Manual creation or modification is prohibited.
5. **Error Logging Required**: All failures must be documented with error type, message, timestamp, and context.

## Error Handling Matrix
| Error Type | Action | Next Steps |
| --- | --- | --- |
| Kusto MCP connection failure | STOP execution, log connection error | Verify MCP configuration and cluster accessibility |
| Kusto query execution failure | STOP execution, log query and error details | Contact service owner to verify table name and permissions |
| Empty query results | STOP execution, log warning | Confirm query parameters and ServiceOid |
| CSV export failure | STOP execution, log I/O error | Check disk space and write permissions |
| transform.ps1 execution failure | STOP execution, log exception details | Review script logic and input data format |
| Data validation failure | STOP execution, log validation errors | Inspect data integrity and format compliance |
| File format mismatch | STOP execution, log expected vs actual format | Verify CSV headers match required columns |

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
1. **Run Kusto query** to enumerate VMs missing AzSecPack:
	```kusto
	ADX_UpgradePolicyMode_Details('Azure SignalR Service', '624c481d-e51c-4016-a522-fbe180d125fc', 'Prod_AzSecPack_UpgradePolicy_KPI_Details')
    | project SubscriptionId, SubscriptionName, Region, ResourceGroup, RoleInstanceName
    | order by Region asc, RoleInstanceName asc
	```
   > **🛑 FAILURE HANDLING**: If Kusto query fails (connection error, permission denied, table not found, etc.), STOP immediately. Log the complete error message and context. Do NOT proceed to next steps.

2. **Save query results to CSV file**:
   - Export the Kusto query results to a CSV file with required columns: `SubscriptionId`, `SubscriptionName`, `Region`, `ResourceGroup`, `RoleInstanceName`, `IsRunningAzSecPack`.
   - Name the file descriptively (e.g., `kusto_results_yyyyMMdd.csv`) and store it in the run directory.
   > **🛑 FAILURE HANDLING**: If export fails or returns zero rows, STOP immediately. Log the error. Never manually create or populate CSV files with mock data.

3. **Run transform.ps1** to convert and validate the data:
   ```powershell
   .\transform.ps1 -InputFile ".\kusto_results_yyyyMMdd.csv"
   ```
   The script will:
   - Validate the CSV format and required columns
   - Transform `RoleInstanceName` to `AgentNodeName` (base-10 to base-36 conversion)
   - Concatenate `SubscriptionId` + `ResourceGroup` to create `ACSCluster`
   - Sort results by Region
   - Generate timestamped output files (`.csv`, `.md`, `.txt`)
   > **🛑 FAILURE HANDLING**: If script execution fails or validation errors occur, STOP immediately. Log the complete error output and stack trace. Do NOT proceed with invalid data.

4. **Review transformation output**:
   - `ACSCluster`: Concatenate `SubscriptionId` and `ResourceGroup` without separators (example: `720cfcbe-dd20-4df4-85b0-221e7f17a569srprodacsaueb`).
   - `AgentNodeName`: Convert `RoleInstanceName` to the Geneva agent format by translating the numeric suffix from base-10 to base-36 while preserving Azure VM naming rules (example: `k8s-ingress-000008-z2-vmss_35` → `k8s-ingress-000008-z2-vmss00000Z`).
   > **🛑 FAILURE HANDLING**: If output format is incorrect or unexpected, STOP immediately. Log the discrepancies and report anomalies.

5. **Validate the payload** for duplicates, malformed names, or unsupported regions before remediation.
   > **🛑 FAILURE HANDLING**: If validation detects any data quality issues, STOP immediately. Log all validation errors with affected records.

## Output Expectations
- **Execution Result** (retain in the run log):
	| SubscriptionId | SubscriptionName | Region | ResourceGroup | RoleInstanceName |
	| --- | --- | --- | --- | --- |
	| ... | ... | ... | ... | ... |

- **Final Result** (GenevaActions batch file):
	```text
	ACSCluster,AgentNodeName
	...,...
	...,...
	```

## Recording Results
- Create a run result named `yyyyMMddfff.md` (`fff` = milliseconds, UTC) in `output/S360_SecurityPack/` after **successful** execution only.
- Create a run log named `yyyyMMddfff.txt` to capture execution steps: Summary, Executed Steps, Status (Success or Failure with detailed error messages and exceptions).
- **For failed executions**: Create ONLY the log file (.txt) documenting the failure point, error type, error message, and timestamp. Do NOT create result files (.md, .csv) for failed runs.
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
- Schedule follow-up validation once GenevaActions completes to verify AzSecPack deployment.


