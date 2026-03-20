# Azure AD Empty Groups Exporter

[![Release](https://img.shields.io/github/v/release/TychoLoke/azure-ad-empty-groups-exporter)](https://github.com/TychoLoke/azure-ad-empty-groups-exporter/releases)
[![CI](https://img.shields.io/github/actions/workflow/status/TychoLoke/azure-ad-empty-groups-exporter/powershell-ci.yml?branch=main)](https://github.com/TychoLoke/azure-ad-empty-groups-exporter/actions/workflows/powershell-ci.yml)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

This PowerShell script finds empty Microsoft Entra groups and exports them to CSV for cleanup review.

## What It Does

- Retrieves all groups from Microsoft Entra ID
- Flags groups with no direct members
- Optionally excludes groups that are members of other groups
- Classifies each group by type and origin
- Bootstraps `PowerShellAdminHelpers` from `TychoLoke/powershell-admin-helpers` if needed

## Requirements

- PowerShell 7 recommended
- Permission to install PowerShell modules for the current user
- Delegated Microsoft Graph access to `Group.Read.All` and `Directory.Read.All`
- Internet access the first time you run the script so it can bootstrap the shared helper module

## Usage

```powershell
.\Export-AzureAD-EmptyGroups.ps1 -OutputPath "C:\Temp\EmptyGroups.csv"
```

To also exclude groups that are members of other groups:

```powershell
.\Export-AzureAD-EmptyGroups.ps1 -OutputPath "C:\Temp\EmptyGroups.csv" -IncludeMembershipChecks
```

## Notes

- The script installs `Microsoft.Graph.Groups` automatically if it is missing.
- The export directory is created automatically.
- This report is useful for tenant cleanup, but you should still validate business ownership before removing groups.

## License

This project is licensed under the MIT License.
