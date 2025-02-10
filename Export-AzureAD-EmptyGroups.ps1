<#
.SYNOPSIS
    Fetches all empty groups from Microsoft Entra ID (Azure AD), categorizes them, and exports them to a CSV file.
    Includes information about whether the group is on-premises or cloud-only.

.DESCRIPTION
    This script:
    - Fetches all Azure AD groups.
    - Identifies empty groups (no members and no group memberships).
    - Categorizes groups by type (e.g., Microsoft 365, Security).
    - Checks if a group is on-premises synced or cloud-only.
    - Exports the results to a CSV file.

.PARAMETER OutputPath
    The full file path where the CSV report will be saved.

.EXAMPLE
    .\Export-AzureAD-EmptyGroups.ps1 -OutputPath "C:\Temp\EmptyGroups.csv"
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

# Connect to Microsoft Graph
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
        # Check direct group members
        $members = Get-MgGroupMember -GroupId $group.Id -ErrorAction Stop

        # Check if the group has memberships in other groups
        $groupMemberships = Get-MgGroupMemberOf -GroupId $group.Id -ErrorAction Stop

        # Process only if the group has no direct members AND no group memberships
        if (($members.Count -eq 0) -and ($groupMemberships.Count -eq 0)) {
            # Determine group type
            $groupType = if ($group.groupTypes -and $group.groupTypes -contains "Unified" -and $group.securityEnabled) { "Microsoft 365 (security-enabled)" }
            elseif ($group.groupTypes -and $group.groupTypes -contains "Unified" -and -not $group.securityEnabled) { "Microsoft 365" }
            elseif (-not ($group.groupTypes -and $group.groupTypes -contains "Unified") -and $group.securityEnabled -and $group.mailEnabled) { "Mail-enabled security" }
            elseif (-not ($group.groupTypes -and $group.groupTypes -contains "Unified") -and $group.securityEnabled) { "Security" }
            elseif (-not ($group.groupTypes -and $group.mailEnabled)) { "Distribution" }
            else { "N/A" }

            # Determine if the group is on-premises synced or cloud-only
            $groupOrigin = if ($group.OnPremisesSyncEnabled -eq $true) { "On-Premises" }
            elseif ($group.OnPremisesSyncEnabled -eq $false) { "Cloud-Only" }
            else { "Unknown" }

            # Add group to report
            $Report.Add([PSCustomObject]@{
                DisplayName = $group.DisplayName
                Id          = $group.Id
                GroupType   = $groupType
                GroupOrigin = $groupOrigin
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
