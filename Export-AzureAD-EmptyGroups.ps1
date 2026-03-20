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
    [string]$OutputPath,

    [switch]$IncludeMembershipChecks
)

function Initialize-PowerShellAdminHelpers {
    $moduleName = "PowerShellAdminHelpers"

    if (-not (Get-Module -ListAvailable -Name $moduleName)) {
        $installerPath = Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "Install-PowerShellAdminHelpers.ps1"
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/TychoLoke/powershell-admin-helpers/main/Install-PowerShellAdminHelpers.ps1" -OutFile $installerPath
        & $installerPath
    }

    Import-Module -Name $moduleName -Force -ErrorAction Stop
}

Initialize-PowerShellAdminHelpers
Ensure-OutputDirectory -Path (Split-Path -Path $OutputPath -Parent)
Ensure-Module -ModuleName "Microsoft.Graph.Groups"

Write-Output "Connecting to Microsoft Graph..."
Connect-GraphWithScopes -Scopes @("Group.Read.All", "Directory.Read.All")

# Fetch all groups
Write-Output "Fetching all groups from Microsoft Entra ID..."
$Groups = Get-MgGroup -All -Property "id,displayName,groupTypes,securityEnabled,mailEnabled,onPremisesSyncEnabled"
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
        $members = @(Get-MgGroupMember -GroupId $group.Id -All -ErrorAction Stop)

        # Check if the group has memberships in other groups
        $groupMemberships = if ($IncludeMembershipChecks) {
            @(Get-MgGroupMemberOf -GroupId $group.Id -All -ErrorAction Stop)
        } else {
            @()
        }

        # Process only if the group has no direct members AND no group memberships
        if (($members.Count -eq 0) -and ($groupMemberships.Count -eq 0)) {
            # Determine group type
            $groupType = if ($group.groupTypes -and $group.groupTypes -contains "Unified" -and $group.securityEnabled) { "Microsoft 365 (security-enabled)" }
            elseif ($group.groupTypes -and $group.groupTypes -contains "Unified" -and -not $group.securityEnabled) { "Microsoft 365" }
            elseif (-not ($group.groupTypes -and $group.groupTypes -contains "Unified") -and $group.securityEnabled -and $group.mailEnabled) { "Mail-enabled security" }
            elseif (-not ($group.groupTypes -and $group.groupTypes -contains "Unified") -and $group.securityEnabled) { "Security" }
            elseif (-not ($group.groupTypes -and $group.groupTypes -contains "Unified") -and $group.mailEnabled -and -not $group.securityEnabled) { "Distribution" }
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
                DirectMembersCount = $members.Count
                ParentGroupMemberships = $groupMemberships.Count
            })
        }
    }
    catch {
        Write-Warning "Failed to process group: $($group.DisplayName) (ID: $($group.Id))"
    }
}

Write-Output "Exporting report to: $OutputPath..."
$Report | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8

Write-Output "✅ Report successfully exported to: $OutputPath"

if (Get-MgContext) {
    Disconnect-MgGraph | Out-Null
}
