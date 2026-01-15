# S360 FIPS - Data Transformation Script
# Converts Kusto query results to GenevaActions batch format

function Convert-ToBase36 {
    param([int]$Number)
    
    $chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    if ($Number -eq 0) { return '0' }
    
    $result = ''
    while ($Number -gt 0) {
        $remainder = $Number % 36
        $result = $chars[$remainder] + $result
        $Number = [Math]::Floor($Number / 36)
    }
    return $result
}

function Convert-RoleName {
    param([string]$Name)
    
    # Pattern: prefix_decimal -> prefix00000BASE36
    if ($Name -match '^(.+)_(\d+)$') {
        $prefix = $matches[1]
        $decimal = [int]$matches[2]
        $base36 = Convert-ToBase36 -Number $decimal
        # Pad with zeros to 5 digits then add base36
        return "${prefix}00000${base36}"
    }
    return $Name
}

# Query results data (from Kusto)
$queryData = @(
    @{SubscriptionId='b51dacb4-4e4e-4036-905b-0da503df33e8'; SubscriptionName='AzureSignalR Production EastUS2'; ResourceGroup='SRPRODACSEUS2A'; RoleName='_k8s-signalr-21129879-z2-vmss_1005'},
    @{SubscriptionId='ea40881a-24fb-479c-bb46-ee1b32b8a5d6'; SubscriptionName='AzureSignalR Production WestUS'; ResourceGroup='SRPRODACSWESTUSB'; RoleName='_k8s-signalr-79468599-vmss_1513'},
    @{SubscriptionId='14f86bfa-5ad1-4404-b8c9-e2b0916a2faf'; SubscriptionName='AzureSignalR Production SouthCentralUS'; ResourceGroup='SRPRODACSSCUSB'; RoleName='_k8s-signalr-86577201-z2-vmss_733'},
    @{SubscriptionId='b51dacb4-4e4e-4036-905b-0da503df33e8'; SubscriptionName='AzureSignalR Production EastUS2'; ResourceGroup='SRPRODACSEUS2A'; RoleName='_k8s-signalr-21129879-z1-vmss_1106'},
    @{SubscriptionId='14f86bfa-5ad1-4404-b8c9-e2b0916a2faf'; SubscriptionName='AzureSignalR Production SouthCentralUS'; ResourceGroup='SRPRODACSSCUSB'; RoleName='_k8s-signalr-86577201-z2-vmss_735'},
    @{SubscriptionId='ea40881a-24fb-479c-bb46-ee1b32b8a5d6'; SubscriptionName='AzureSignalR Production WestUS'; ResourceGroup='SRPRODACSWESTUSB'; RoleName='_k8s-signalr-79468599-vmss_1506'},
    @{SubscriptionId='14f86bfa-5ad1-4404-b8c9-e2b0916a2faf'; SubscriptionName='AzureSignalR Production SouthCentralUS'; ResourceGroup='SRPRODACSSCUSB'; RoleName='_k8s-signalr-86577201-z3-vmss_686'},
    @{SubscriptionId='ea40881a-24fb-479c-bb46-ee1b32b8a5d6'; SubscriptionName='AzureSignalR Production WestUS'; ResourceGroup='SRPRODACSWESTUSB'; RoleName='_k8s-signalr-79468599-vmss_500'},
    @{SubscriptionId='7387ad35-91d4-42a3-b02e-7c548e7d7614'; SubscriptionName='AZURESIGNALR FAIRFAX USGOV ARIZONA'; ResourceGroup='SRFFACSUSAZB'; RoleName='_k8s-master-17497956-0'},
    @{SubscriptionId='14f86bfa-5ad1-4404-b8c9-e2b0916a2faf'; SubscriptionName='AzureSignalR Production SouthCentralUS'; ResourceGroup='SRPRODACSSCUSA'; RoleName='_k8s-signalr-31519765-z3-vmss_204'}
)

# Transform to GenevaActions format
$genevaActionsData = @()
$executionResults = @()

foreach ($item in $queryData) {
    # Build ACSCluster: SubscriptionId + ResourceGroup (no separator)
    $acsCluster = $item.SubscriptionId + $item.ResourceGroup
    
    # Convert RoleName to AgentNodeName
    $agentNodeName = Convert-RoleName -Name $item.RoleName
    
    $genevaActionsData += [PSCustomObject]@{
        ACSCluster = $acsCluster
        AgentNodeName = $agentNodeName
    }
    
    $executionResults += [PSCustomObject]@{
        SubscriptionId = $item.SubscriptionId
        SubscriptionName = $item.SubscriptionName
        ResourceGroup = $item.ResourceGroup
        RoleName = $item.RoleName
    }
}

# Export results
$timestamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmssfff')
$resultPath = "d:\Code\GitHub_JX\x-tests\Tasks\S360_FIPS\$timestamp.md"
$logPath = "d:\Code\GitHub_JX\x-tests\Tasks\S360_FIPS\$timestamp.txt"
$csvPath = "d:\Code\GitHub_JX\x-tests\Tasks\S360_FIPS\$timestamp.csv"

# Create GenevaActions CSV
$genevaActionsData | Export-Csv -Path $csvPath -NoTypeInformation

Write-Output "Transformation complete!"
Write-Output "Total VMs processed: $($queryData.Count)"
Write-Output "GenevaActions batch file: $csvPath"
Write-Output ""
Write-Output "First 5 transformed records:"
$genevaActionsData | Select-Object -First 5 | Format-Table -AutoSize

# Return paths for file creation
@{
    Timestamp = $timestamp
    ExecutionResults = $executionResults
    GenevaActionsData = $genevaActionsData
}
