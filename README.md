# Get-ADLockouts

PowerShell script/module to find, report, and export locked-out Active Directory user accounts.

## Synopsis

Get-ADLockouts scans Active Directory for locked-out user accounts and returns a sortable, filterable report. It supports CSV/JSON export, scheduled runs, and easy piping into further automation (unlock, notify, audit).

## Features

- Detects locked-out AD user accounts across domains or against a specified domain controller
- Returns rich properties for each locked account (SAM account, DN, lockout time, last bad password attempt, last logon, manager, enabled state)
- Export to CSV or JSON
- Easily scriptable for notifications (email, Teams, Slack) and remedial actions (unlock, disable)
- Works in Windows PowerShell 5.1 and PowerShell 7+ (with ActiveDirectory module available)

## Installation

From the PowerShell Gallery (recommended):

```powershell
Install-Module -Name Get-ADLockouts -Scope CurrentUser
```

Or clone the repository and import the module:

```powershell
git clone https://github.com/brooksrockett/Get-ADLockouts.git
Import-Module .\Get-ADLockouts\Get-ADLockouts.psm1
```

## Requirements

- Windows with network connectivity to a domain controller
- Active Directory PowerShell module (RSAT/ActiveDirectory) available:
  - On Windows 10/11/Server: Install-WindowsFeature RSAT-AD-PowerShell or enable RSAT feature
  - On PowerShell 7+, you may need WindowsCompatibility/Import-Module -UseWindowsPowerShell
- Account with permissions to read user objects in AD (Domain Users can usually read most attributes). Unlocking accounts requires additional rights (Reset Password / Unlock Account).

## Typical Usage

Basic: list all locked-out users in the current domain

```powershell
Get-ADLockouts
```

Query a specific domain controller:

```powershell
Get-ADLockouts -Server dc01.corp.contoso.com
```

Export to CSV:

```powershell
Get-ADLockouts | Export-Csv -Path "C:\Reports\AD-Lockouts-$(Get-Date -Format yyyyMMdd).csv" -NoTypeInformation
```

Export to JSON:

```powershell
Get-ADLockouts | ConvertTo-Json -Depth 4 | Out-File "C:\Reports\AD-Lockouts.json"
```

Filter by OU:

```powershell
Get-ADLockouts -SearchBase "OU=Employees,DC=corp,DC=contoso,DC=com"
```

Unlock matching accounts (use caution — review results first):

```powershell
Get-ADLockouts | ForEach-Object {
    Unlock-ADAccount -Identity $_.DistinguishedName -Confirm:$false
}
```

Send a notification email for each lockout (example using Send-MailMessage):

```powershell
Get-ADLockouts | ForEach-Object {
    $body = "User $($_.SamAccountName) locked out at $($_.LockedOutTime)."
    Send-MailMessage -From "ad-alerts@contoso.com" -To "itops@contoso.com" -Subject "AD Lockout: $($_.SamAccountName)" -Body $body -SmtpServer "smtp.contoso.com"
}
```

## Parameters (common)

Note: If the module contains different parameter names, adapt the examples accordingly.

- -Server
  - Type: String
  - Description: Domain controller or LDAP server to query (FQDN). Defaults to the current domain.
- -SearchBase
  - Type: String
  - Description: LDAP path (DN) to scope searches (e.g., an OU).
- -Credential
  - Type: PSCredential
  - Description: Alternate credentials to use when querying AD.
- -IncludeDisabled
  - Type: Switch
  - Description: Include disabled accounts in the output (default: only locked and enabled accounts).
- -WhatIf / -Confirm
  - Standard PowerShell switches for destructive actions (unlocking, disabling).

## Output

The cmdlet returns objects with properties similar to:

- SamAccountName
- Name
- DistinguishedName
- LockedOut (Boolean)
- LockedOutTime (DateTime) — best-effort; may be null depending on DC replication and attribute availability
- LastBadPasswordAttempt (DateTime)
- LastLogon / LastLogonTimestamp (DateTime)
- Enabled (Boolean)
- WhenCreated (DateTime)
- Manager
- Department
- EmailAddress

These objects are pipeline-friendly and can be exported or piped into other AD cmdlets.

## Scheduling

To run daily and export results:

1. Save a PowerShell script (e.g., C:\Scripts\Export-ADLockouts.ps1):

```powershell
Import-Module Get-ADLockouts
Get-ADLockouts | Export-Csv "C:\Reports\AD-Lockouts-$(Get-Date -Format yyyyMMdd).csv" -NoTypeInformation
```

2. Create a Scheduled Task using Task Scheduler to run the script under a service account with appropriate AD read permissions.

Alternatively use Azure Automation/Runbooks for cloud scheduling and notification.

## Security & Privacy

- The script only queries AD read attributes by default. Unlock or reset-password actions should only be executed by authorized administrators.
- Do not store plaintext credentials in scripts. Use secured service accounts and Managed Service Accounts where possible.
- Ensure exported reports are stored securely (restricted ACLs) because they contain privileged account information.

## Troubleshooting

- Error: "The term 'Get-ADUser' is not recognized" — ensure RSAT/ActiveDirectory module is installed and imported.
- Inconsistent LockedOutTime or LastBadPasswordAttempt — AD replication and attribute write behavior vary by DC; consider querying the PDC emulator for the most recent data for lockout events.
- Permission denied — verify the account used to query AD has read access to the target OU/domain.

## Examples (full)

List locked-out users and show selected fields:

```powershell
Get-ADLockouts | Select-Object Name, SamAccountName, LockedOutTime, LastBadPasswordAttempt, Enabled | Format-Table -AutoSize
```

Save non-empty reports (skip creating empty files):

```powershell
$results = Get-ADLockouts
if ($results) {
    $results | Export-Csv -Path "C:\Reports\AD-Lockouts-$(Get-Date -Format yyyyMMdd).csv" -NoTypeInformation
}
```

## Contributing

Contributions, issues, and feature requests are welcome. Please open a GitHub issue or submit a pull request. Follow the project’s coding style and include tests/examples where appropriate.

## Change Log

See CHANGELOG.md (if present) or GitHub releases for details.

## License

Specify your preferred license, e.g., MIT License. Update the repository license file accordingly.

## Support

If you want the README tailored to reflect the actual script parameters and examples exactly, grant repository access for a quick scan or paste the main script/module file here and I’ll update the README to match precisely.