# S360 SecurityPack - Data Transformation Script
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

function Convert-RoleInstanceName {
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
    @{SubscriptionId='720cfcbe-dd20-4df4-85b0-221e7f17a569'; SubscriptionName='AzureSignalR Production AustraliaEast'; Region='Australia East'; ResourceGroup='srprodacsaueb'; RoleInstanceName='k8s-egwebpubsub-92268319-z1-vmss_1'; IsRunningAzSecPack='NO'},
    @{SubscriptionId='720cfcbe-dd20-4df4-85b0-221e7f17a569'; SubscriptionName='AzureSignalR Production AustraliaEast'; Region='Australia East'; ResourceGroup='srprodacsaueb'; RoleInstanceName='k8s-egwebpubsub-92268319-z2-vmss_0'; IsRunningAzSecPack='NO'},
    @{SubscriptionId='9ac1c814-ec67-4a83-b4c8-924116c868f9'; SubscriptionName='AzureSignalR Bleu  bleuc'; Region='Bleu France Central'; ResourceGroup=''; RoleInstanceName='aks-rp-15381743-vmss_0'; IsRunningAzSecPack='NO'},
    @{SubscriptionId='9ac1c814-ec67-4a83-b4c8-924116c868f9'; SubscriptionName='AzureSignalR Bleu  bleuc'; Region='Bleu France Central'; ResourceGroup=''; RoleInstanceName='aks-rp-15381743-vmss_1'; IsRunningAzSecPack='NO'},
    @{SubscriptionId='9ac1c814-ec67-4a83-b4c8-924116c868f9'; SubscriptionName='AzureSignalR Bleu  bleuc'; Region='Bleu France Central'; ResourceGroup=''; RoleInstanceName='aks-rp-15381743-vmss_2'; IsRunningAzSecPack='NO'},
    @{SubscriptionId='9ac1c814-ec67-4a83-b4c8-924116c868f9'; SubscriptionName='AzureSignalR Bleu  bleuc'; Region='Bleu France Central'; ResourceGroup=''; RoleInstanceName='aks-rp-15381743-vmss_3'; IsRunningAzSecPack='NO'},
    @{SubscriptionId='9ac1c814-ec67-4a83-b4c8-924116c868f9'; SubscriptionName='AzureSignalR Bleu  bleuc'; Region='Bleu France Central'; ResourceGroup=''; RoleInstanceName='aks-rp-15381743-vmss_4'; IsRunningAzSecPack='NO'},
    @{SubscriptionId='9ac1c814-ec67-4a83-b4c8-924116c868f9'; SubscriptionName='AzureSignalR Bleu  bleuc'; Region='Bleu France Central'; ResourceGroup=''; RoleInstanceName='aks-system-15381743-vmss_0'; IsRunningAzSecPack='NO'},
    @{SubscriptionId='f6449602-c95f-4ebb-a12d-ad164dc41c8d'; SubscriptionName='AzureSignalR Production BrazilSouth'; Region='Brazil South'; ResourceGroup='srprodacsbrsa'; RoleInstanceName='k8s-system-27916122-vmss_0'; IsRunningAzSecPack='NO'},
    @{SubscriptionId='c67c7f54-2c85-4ef7-90ca-f9488da97c7f'; SubscriptionName='AzureSignalR Production CanadaCentral'; Region='Canada Central'; ResourceGroup='srprodacscacea'; RoleInstanceName='k8s-egwebpubsub-77314816-z2-vmss_1'; IsRunningAzSecPack='NO'}
)

# Transform to GenevaActions format
$genevaActionsData = @()
$executionResults = @()

foreach ($item in $queryData) {
    # Build ACSCluster: SubscriptionId + ResourceGroup (no separator)
    $acsCluster = $item.SubscriptionId + $item.ResourceGroup
    
    # Convert RoleInstanceName to AgentNodeName
    $agentNodeName = Convert-RoleInstanceName -Name $item.RoleInstanceName
    
    $genevaActionsData += [PSCustomObject]@{
        ACSCluster = $acsCluster
        AgentNodeName = $agentNodeName
    }
    
    $executionResults += [PSCustomObject]@{
        SubscriptionId = $item.SubscriptionId
        SubscriptionName = $item.SubscriptionName
        Region = $item.Region
        ResourceGroup = $item.ResourceGroup
        RoleInstanceName = $item.RoleInstanceName
    }
}

# Export results
$timestamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmssfff')
$resultPath = "d:\Code\GitHub_JX\x-tests\Tasks\S360_SecurityPack\$timestamp.md"
$logPath = "d:\Code\GitHub_JX\x-tests\Tasks\S360_SecurityPack\$timestamp.txt"
$csvPath = "d:\Code\GitHub_JX\x-tests\Tasks\S360_SecurityPack\$timestamp.csv"

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
