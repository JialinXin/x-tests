# vuln-management

# Vuln Management - Product and Data Overview Template

## 1. Product Overview

Vuln Management is a reporting and analytics solution for vulnerability data across container images, VMs, and related assets. It aggregates scan results, compliance attributes, and prioritization logic to support security and FedRAMP reporting.

## 2. Data Platform Overview

- **Data Storage**: Azure Data Explorer (ADX)
- **Product**: Vuln Management
- **Product Nick Names**: 
**[TODO]Data_Engineer**: Fill in commonly used short names or abbreviations for the product to help PMAgent accurately recognize the target product from user conversations.
- **Kusto Cluster**: signalrinsights.eastus2.kusto.windows.net (main dashboard cluster)
- **Kusto Database**: SignalRBI (main dashboard database)
- **Primary Metrics**: 
**[TODO]Data_Engineer**: Describe the key metrics used to measure vulnerability management performance, e.g.:
  - Vulnerability count by asset type
  - FedRAMPPriority (compliance priority)
  - OldestVuln (oldest open vulnerability)
  - ImageCount (distinct images with vulnerabilities)
  - Priority (custom logic for P0/P1/P2 assignment)

## 3. Table Schemas in Azure Data Explorer

> Table schemas are inferred from dashboard queries and may require Data Engineer review for accuracy.

### 3.1 VulnDetailsContainerImage (cluster: shavulnmgmtprdwus.kusto.windows.net, database: ShaVulnMgmt)

| Column            | Type     | Description                                  |
|-------------------|----------|----------------------------------------------|
| ServiceTreeId     | string   | Service identifier                           |
| RunId             | datetime | Scan run timestamp                           |
| IsActionable      | bool     | Indicates actionable vulnerability           |
| ScanAttributes    | dynamic  | JSON attributes about the scan               |
| VulnerabilityAttributes | dynamic | JSON attributes about the vulnerability |
| ComplianceAttributes | dynamic | JSON attributes about compliance           |
| ImageId           | string   | Container image identifier                   |
| ImageName         | string   | Full image name                              |
| AssetType         | string   | Type of asset (e.g., ContainerImage)         |
| Environment       | string   | Environment (e.g., Prod, PPE)                |
| Cloud             | string   | Cloud provider                               |
| VulnerabilityId   | string   | Vulnerability identifier                     |
| VulnerabilityName | string   | Vulnerability name                           |
| DueDate           | datetime | Vulnerability due date                       |
| FedRAMPPriority   | int      | Compliance priority                          |
| ShortImageName    | string   | Parsed short image name                      |

### 3.2 VulnDetails (cluster: shavulnmgmtprdwus.kusto.windows.net, database: ShaVulnMgmt)

| Column            | Type     | Description                                  |
|-------------------|----------|----------------------------------------------|
| ServiceTreeId     | string   | Service identifier                           |
| RunId             | datetime | Scan run timestamp                           |
| IsActionable      | bool     | Indicates actionable vulnerability           |
| InventoryAttributes | dynamic | JSON attributes about inventory              |
| VulnerabilityAttributes | dynamic | JSON attributes about the vulnerability |
| AssetType         | string   | Type of asset (e.g., VM, ContainerImage)     |
| Environment       | string   | Environment (e.g., Prod, PPE)                |
| RoleName          | string   | VM role name                                 |
| SubscriptionName  | string   | Azure subscription name                      |
| ResourceGroup     | string   | Azure resource group                         |
| DueDate           | datetime | Vulnerability due date                       |
| VulnerabilityId   | string   | Vulnerability identifier                     |

### 3.3 Container_Details (cluster: shavulnmgmtprdwus.kusto.windows.net, database: ShaReporting2)

| Column            | Type     | Description                                  |
|-------------------|----------|----------------------------------------------|
| ServiceTreeId     | string   | Service identifier                           |
| RunId             | datetime | Scan run timestamp                           |
| IsActionable      | bool     | Indicates actionable vulnerability           |
| ScanAttributes    | dynamic  | JSON attributes about the scan               |
| VulnerabilityAttributes | dynamic | JSON attributes about the vulnerability |
| ComplianceAttributes | dynamic | JSON attributes about compliance           |
| ImageId           | string   | Container image identifier                   |
| ImageName         | string   | Full image name                              |
| AssetType         | string   | Type of asset                                |
| Environment       | string   | Environment (e.g., Prod, PPE)                |
| Cloud             | string   | Cloud provider                               |
| DueDate           | datetime | Vulnerability due date                       |
| FedRAMPPriority   | int      | Compliance priority                          |
| Priority          | string   | Custom priority (P0/P1/P2)                   |
| Week              | datetime | Week grouping for trend analysis             |

### 3.4 FedRAMP_InventoryHourly (cluster: agesconmonadx.westus2, database: conmon)

| Column            | Type     | Description                                  |
|-------------------|----------|----------------------------------------------|
| AssetSubType      | string   | Asset subtype (e.g., Linux)                  |
| OSBasic           | string   | Basic OS info                                |
| OS                | string   | OS version                                   |
| Judgment          | string   | Compliance judgment                          |
| AssetId           | string   | Asset identifier                             |
| ScanResult        | string   | Scan result                                  |
| ServiceTreeId     | string   | Service identifier                           |
| ServiceTreeName   | string   | Service name                                 |
| Cloud             | string   | Cloud provider                               |
| SubscriptionName  | string   | Azure subscription name                      |
| Cluster           | string   | Cluster name                                 |
| ResourceGroup     | string   | Resource group                               |
| VMScaleSetName    | string   | VMSS name                                    |
| RoleName          | string   | VM role name                                 |
| AssetType         | string   | Asset type                                   |
| FedRAMPPriority   | int      | Compliance priority                          |

### 3.5 FedRAMP_Services (cluster: agesconmonadx.westus2, database: conmon)

| Column            | Type     | Description                                  |
|-------------------|----------|----------------------------------------------|
| ServiceTreeId     | string   | Service identifier                           |
| DivisionName      | string   | Division name                                |
| OrganizationName  | string   | Organization name                            |
| ServiceGroupName  | string   | Service group name                           |
| TeamGroupName     | string   | Team group name                              |
| ToLine            | string   | Additional info                              |

### 3.6 VulnLastScan (cluster: shavulnmgmtprdwus.kusto.windows.net, database: ShaVulnMgmt)

| Column            | Type     | Description                                  |
|-------------------|----------|----------------------------------------------|
| AssetId           | string   | Asset identifier                             |
| ScanResult        | string   | Scan result                                  |

## 4. Common Analytical Scenarios

**[TODO]Data_Engineer** Review or supplement this section with representative product usage scenarios.

- Vulnerability count by asset type and environment
- Trend analysis of container image vulnerabilities (weekly, monthly)
- Compliance prioritization (FedRAMPPriority, custom P0/P1/P2 logic)
- Oldest open vulnerability tracking
- Image distribution by ownership (external vs. owned)
- OS compliance status (e.g., Mariner OS, Azure Linux)

## 5. Common Filters and Definitions

**[TODO]Data_Engineer** Review or add product specific and common known filters.

- Exclude non-actionable vulnerabilities:
  ```Kusto
  | where IsActionable
  ```
- Filter by environment:
  ```Kusto
  | where Environment == 'Prod'
  ```
- Exclude known test or PPE environments:
  ```Kusto
  | where Environment != 'PPE'
  ```
- Exclude specific vulnerability IDs (e.g., known K8S issues):
  ```Kusto
  | where VulnerabilityId !in ('377841', '377844')
  ```
- Custom priority assignment:
  ```Kusto
  | extend Priority = case(DueDate < RunId, 'P0', DueDate < RunId + 14d, 'P1', 'P2')
  ```
- OS compliance mapping:
  ```Kusto
  | extend Judgment = case(
      OS contains "202408" or OS contains "202410" or OS contains "202411" or OS contains "202412", 'Current Mariner OS',
      OS contains "202407" or OS contains "202406" or OS contains "202405" or OS contains "202404" or OS contains "202403"
          or OS contains "2023" or OS contains "202402" or OS contains "202401", 'Behind Mariner OS',
      OS contains "azurelinux-3.0", 'Azure Linux 3.0 is NOT approved for FedRAMP use yet. Downgrade to 2.0',
      '')
  ```

## 6. Notes and Considerations

**[TODO]Data_Engineer**: Content Guidance: Include important operational notes, data limitations, and analysis best practices specific to this product.

- All timestamps are in **UTC**.
- Data may be distributed across multiple clusters and databases.
- For accuracy, use `count()` and `dcount()` for aggregation.
- Always filter to actionable vulnerabilities and production environments for compliance reporting.
- Custom logic for priority and OS compliance should be reviewed and updated as business rules evolve.

## 7. Sample Queries

> Representative queries inferred from dashboard logic.

### 7.1 Vulnerability count by container image (weekly trend)

```Kusto
cluster('shavulnmgmtprdwus.kusto.windows.net').database('ShaReporting2').Container_Details
| where ServiceTreeId == '<ServiceId>' and IsActionable and RunId >= startofweek(now(), -8)
| extend DataSource = tostring(ScanAttributes.DataSource), ImageId = tostring(ScanAttributes.ImageId), ImageName = tostring(ScanAttributes.ImageName),
    DueDate = todatetime(VulnerabilityAttributes.DueDate), FedRAMPPriority = toint(ComplianceAttributes.FedRAMPPriority)
| where DataSource contains 'AzSecPack' and Environment == 'Prod'
| extend Priority = case(DueDate < RunId, 'P0', DueDate < RunId + 14d, 'P1', 'P2'), Week = iif(RunId < startofweek(now()), startofday(endofweek(RunId)), startofday(now()))
| extend FedRAMPPriority = iif(isempty(FedRAMPPriority), 2, FedRAMPPriority)
| where startofday(RunId) == Week
| summarize arg_max(RunId, *) by ImageName, Week
| summarize FedRAMPPriority = min(FedRAMPPriority) by Week, ImageId, ImageName
| summarize ImageCount = dcount(ImageId) by Week, FedRAMPPriority
```

### 7.2 OS compliance status for Linux assets

```Kusto
cluster('agesconmonadx.westus2').database('conmon').FedRAMP_InventoryHourly
| where AssetSubType contains "Linux" or OSBasic contains "Mariner"
| extend Judgment = case(
    OS contains "202408" or OS contains "202410" or OS contains "202411" or OS contains "202412", 'Current Mariner OS',
    OS contains "202407" or OS contains "202406" or OS contains "202405" or OS contains "202404" or OS contains "202403"
        or OS contains "2023" or OS contains "202402" or OS contains "202401", 'Behind Mariner OS',
    OS contains "azurelinux-3.0", 'Azure Linux 3.0 is NOT approved for FedRAMP use yet. Downgrade to 2.0',
    '')
| where Judgment !in ('Current Mariner OS','')
| project ServiceTreeId, ServiceTreeName, Cloud, SubscriptionName, Cluster, ResourceGroup, VMScaleSetName, RoleName, AssetId, OS, Judgment, AssetType, FedRAMPPriority
```

### 7.3 Exclude known test environments and vulnerabilities

```Kusto
cluster('shavulnmgmtprdwus.kusto.windows.net').database('ShaVulnMgmt').VulnDetails
| where ServiceTreeId == '<ServiceId>' and IsActionable and RunId > ago(1d)
| where VulnerabilityId !in ('377841', '377844') and Environment != 'PPE' and RoleName !startswith 'vmss' and DueDate <= now()
| summarize ResourceGroup = max(ResourceGroup), DueDate = min(DueDate), RunId = max(RunId) by RoleName, Environment, AssetType, SubscriptionName
```


