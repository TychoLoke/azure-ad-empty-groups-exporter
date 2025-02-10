<#
.SYNOPSIS
    Fetches all empty groups from Microsoft Entra ID (Azure AD) and exports them to a CSV file.

.DESCRIPTION
    This script uses the Microsoft Graph PowerShell module to fetch all groups, identifies empty groups,
    determines their type, and exports the results to a specified CSV file. It includes progress updates and error handling.

.PARAMETER OutputPath
    The full file path where the CSV report will be saved.

.EXAMPLE
    .\Export-EmptyGroups.ps1 -OutputPath C:\Temp\EmptyGroups.csv

    This example saves the report to C:\Temp\EmptyGroups.csv.

.NOTES
    Author: Tycho Löke
    Date: February 2025
    Requires: Microsoft.Graph module
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true, HelpMessage = "Specify the output file path for the CSV report.")]
    [string]$OutputPath
)

# Ensure Microsoft.Graph module is installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Output "Installing Microsoft.Graph module..."
    Install-Module Microsoft.Graph -Force -Scope CurrentUser
}

# Import necessary submodule
Import-Module Microsoft.Graph.Groups -ErrorAction Stop

# Connect to Microsoft Graph (ensure the user is authenticated)
Write-Output "Connecting to Microsoft Graph..."
Connect-MgGraph -ErrorAction Stop

# Fetch all groups
Write-Output "Fetching all groups from Microsoft Entra ID..."
$Groups = Get-MgGroup -All
$Report = [System.Collections.Generic.List[Object]]::new()

$totalGroups = $Groups.Count
$currentGroup = 0

Write-Output "Processing groups... This might take some time."

# Loop through groups
foreach ($group in $Groups) {
    $currentGroup++
    Write-Progress -Activity "Checking groups for empty membership" -Status "Processing group $currentGroup of $totalGroups" -PercentComplete (($currentGroup / $totalGroups) * 100)

    try {
        # Fetch group members
        $members = Get-MgGroupMember -GroupId $group.Id -ErrorAction Stop

        if ($members.Count -eq 0) {
            # Determine group type
            $groupType = if ($group.groupTypes -and $group.groupTypes -contains "Unified" -and $group.securityEnabled) { "Microsoft 365 (security-enabled)" }
            elseif ($group.groupTypes -and $group.groupTypes -contains "Unified" -and -not $group.securityEnabled) { "Microsoft 365" }
            elseif (-not ($group.groupTypes -and $group.groupTypes -contains "Unified") -and $group.securityEnabled -and $group.mailEnabled) { "Mail-enabled security" }
            elseif (-not ($group.groupTypes -and $group.groupTypes -contains "Unified") -and $group.securityEnabled) { "Security" }
            elseif (-not ($group.groupTypes -and $group.mailEnabled)) { "Distribution" }
            else { "N/A" }

            # Add group to report
            $Report.Add([PSCustomObject]@{
                DisplayName = $group.DisplayName
                Id          = $group.Id
                GroupType   = $groupType
            })
        }
    }
    catch {
        Write-Warning "Failed to process group: $($group.DisplayName) (ID: $($group.Id))"
    }
}

# Export report to CSV
Write-Output "Exporting report to: $OutputPath..."
if (-not (Test-Path (Split-Path -Path $OutputPath))) {
    New-Item -ItemType Directory -Path (Split-Path -Path $OutputPath) -Force | Out-Null
}

$Report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

Write-Output "✅ Report successfully exported to: $OutputPath"
