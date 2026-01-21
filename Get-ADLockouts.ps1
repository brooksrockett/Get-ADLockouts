<#PSScriptInfo
.VERSION 1.0
.GUID 86565b4b-c9e0-4eb6-a85c-340a1dba00f4
.AUTHOR Brooks Rockett
.COMPANYNAME
.COPYRIGHT
.TAGS
.LICENSEURI
.PROJECTURI
.ICONURI
.EXTERNALMODULEDEPENDENCIES
.REQUIREDSCRIPTS
.EXTERNALSCRIPTDEPENDENCIES
.RELEASENOTES
 
.PRIVATEDATA
#>
<#
.DESCRIPTION
 Retrieve the currently locked out users from Active Directory and the time remaining on the lockout.
#> 
Param()
$users = Search-ADAccount -LockedOut | Get-ADUser -Properties DisplayName, LockedOut, LockoutTime, msDS-User-Account-Control-Computed; if ($null -ne $users) {
    foreach ($user in $users) {
        if ($user.LockedOut) {
            # Get domain policy for lockout duration
            $lockoutDuration = (Get-ADDefaultDomainPasswordPolicy).LockoutDuration
            # Convert LockoutTime to DateTime (it's stored as ticks since 1601-01-01)
            $lockoutTime = [datetime]::FromFileTime($user.LockoutTime)
            # Calculate remaining lockout time
            $unlockTime = $lockoutTime.AddMinutes($lockoutDuration.TotalMinutes)
            $remainingTime = $unlockTime - (Get-Date)
            if ($remainingTime.TotalMinutes -gt 0) {
                Write-Output "Remaining lockout time for User $($user.DisplayName): $($remainingTime.Minutes) minutes, $($remainingTime.Seconds) seconds"
                else {
                    Write-Output "User $($user.DisplayName) can now be unlocked."
                }
            }
            else {
                Write-Output "There are no locked out users."
            }
