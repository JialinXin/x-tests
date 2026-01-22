# S360 SecurityPack - Data Transformation Script
# Converts Kusto query results to GenevaActions batch format
#
# Usage: .\transform.ps1 -InputFile <path-to-csv>
# Example: .\transform.ps1 -InputFile ".\kusto_results.csv"

param(
    [Parameter(Mandatory=$true, HelpMessage="Path to the input CSV file containing Kusto query results")]
    [string]$InputFile
)

# Required columns for input CSV
$requiredColumns = @('SubscriptionId', 'SubscriptionName', 'Region', 'ResourceGroup', 'RoleInstanceName', 'IsRunningAzSecPack')

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

function Test-InputFileFormat {
    param(
        [string]$FilePath,
        [string[]]$RequiredColumns
    )
    
    # Check if file exists
    if (-not (Test-Path $FilePath)) {
        Write-Error "Input file not found: $FilePath"
        return $false
    }
    
    # Read first line to get headers
    $headers = (Get-Content $FilePath -First 1) -split ','
    $headers = $headers | ForEach-Object { $_.Trim().Trim('"') }
    
    # Check for required columns
    $missingColumns = @()
    foreach ($col in $RequiredColumns) {
        if ($col -notin $headers) {
            $missingColumns += $col
        }
    }
    
    if ($missingColumns.Count -gt 0) {
        Write-Error "Missing required columns: $($missingColumns -join ', ')"
        Write-Output "Expected columns: $($RequiredColumns -join ', ')"
        Write-Output "Found columns: $($headers -join ', ')"
        return $false
    }
    
    Write-Output "Input file format validated successfully."
    Write-Output "Found columns: $($headers -join ', ')"
    return $true
}

# Validate input file format
if (-not (Test-InputFileFormat -FilePath $InputFile -RequiredColumns $requiredColumns)) {
    exit 1
}

# Read query data from CSV file
$queryData = Import-Csv -Path $InputFile

# Transform to GenevaActions format
$transformedData = @()

foreach ($item in $queryData) {
    # Build ACSCluster: SubscriptionId + ResourceGroup (no separator)
    $acsCluster = $item.SubscriptionId + $item.ResourceGroup
    
    # Convert RoleInstanceName to AgentNodeName
    $agentNodeName = Convert-RoleInstanceName -Name $item.RoleInstanceName
    
    $transformedData += [PSCustomObject]@{
        ACSCluster = $acsCluster
        AgentNodeName = $agentNodeName
        Region = $item.Region
        SubscriptionId = $item.SubscriptionId
        SubscriptionName = $item.SubscriptionName
        ResourceGroup = $item.ResourceGroup
        RoleInstanceName = $item.RoleInstanceName
    }
}

# Sort by Region
$sortedData = $transformedData | Sort-Object -Property Region

# Prepare output data
$genevaActionsData = $sortedData | Select-Object ACSCluster, AgentNodeName
$executionResults = $sortedData | Select-Object SubscriptionId, SubscriptionName, Region, ResourceGroup, RoleInstanceName

# Export results
$timestamp = (Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmssfff')
$outputDir = Split-Path -Parent $InputFile
$resultPath = Join-Path $outputDir "$timestamp.md"
$logPath = Join-Path $outputDir "$timestamp.txt"
$csvPath = Join-Path $outputDir "$timestamp.csv"

# Create GenevaActions CSV
$genevaActionsData | Export-Csv -Path $csvPath -NoTypeInformation

Write-Output ""
Write-Output "Transformation complete!"
Write-Output "Input file: $InputFile"
Write-Output "Total VMs processed: $($queryData.Count)"
Write-Output "GenevaActions batch file: $csvPath"
Write-Output "Results sorted by Region"
Write-Output ""
Write-Output "First 5 transformed records (sorted by Region):"
$sortedData | Select-Object Region, ACSCluster, AgentNodeName -First 5 | Format-Table -AutoSize

# Return paths for file creation
@{
    Timestamp = $timestamp
    ExecutionResults = $executionResults
    GenevaActionsData = $genevaActionsData
}
