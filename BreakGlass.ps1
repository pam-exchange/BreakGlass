<#------------------------------------------------------------

This script will extract breakglass accounts from BeyondTrust Password Safe
and store them in KeePassXC.

-------------
History

1.0.0 - 2025-07-xx - First release
------------------------------------------------------------
#>

param (
    [Parameter(Mandatory=$false)][string]$ConfigPath= "c:\temp",
    [Parameter(Mandatory=$false)][switch]$Quiet= $false,
    [Parameter(Mandatory=$false)][switch]$WhatIf= $false
)

try {$startTime= (Get-Date -ErrorAction SilentlyContinue)} catch {$now= 0}

$version= "1.0.0"
$verbose = $VerbosePreference -ne 'SilentlyContinue'

$scriptBasePath= $PSScriptRoot
$scriptName= $PSCommandPath

#
# modulePath
#
if (-not $modulePath) { 
    #$modulePath= $scriptBasePath.substring(0,$scriptBasePath.LastIndexOf("\")) 
    $modulePath= $scriptBasePath
}

$Global:currentPSModulePath= $env:PSModulePath
if ($env:PSModulePath -notmatch ";"+$($modulePath.replace("\","\\"))+"\\modules") {
    $env:PSModulePath+=";$modulePath\modules"
}

if ($(Get-Module).name -contains "Breakglass") { Remove-Module Breakglass }
if ($(Get-Module).name -contains "KeePassXC") { Remove-Module KeePassXC }
if ($(Get-Module).name -contains "PasswordSafe") { Remove-Module PasswordSafe }

Import-Module PasswordSafe -Force
Import-Module KeePassXC -Force
Import-Module Breakglass -Force


# ************************************************************************************
try {

    # 
    # Start-Breakglass will read configuration and 
    # start PasswordSafe and KeePassXC
    #
    Start-Breakglass -ConfigPath $ConfigPath

    #
    # Fetch breakglass accounts from PAM
    #
    if (-not $Quiet -or $WhatIf) {Write-Host "Fetching breakglass accounts from PAM"}
    $pamAccounts= Find-BreakglassFromPAM -PAMType PasswordSafe -Quiet:$Quiet -WhatIf:$WhatIf
    
    if (-not $Quiet -or $WhatIf) {Write-Host "Found $($pamAccounts.count) breakglass accounts in PAM" -ForegroundColor Gray}

    #
    # Sync accounts from PAM with KeePassXC
    #
    if (-not $Quiet -or $WhatIf) {Write-Host "Aligning PAM accounts with KeePassXC"}
    $res= Sync-BreakglassToVault -VaultType KeePassXC -BreakGlassEntries $pamAccounts -CreateDatabase -Quiet:$Quiet -WhatIf:$WhatIf

} 
catch {
    Write-Host "$($_.Exception.Message) - $($_.Exception.Details)" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
}
finally {
    Stop-Breakglass

    if (-not $Quiet -or $WhatIf) {
        try {
            # --- Elapsed time ---
            $t= $([int]((Get-Date -ErrorAction SilentlyContinue)-$startTime).TotalSeconds)

            $h= [int][Math]::Floor( $t / 3600 )
            $m= [int][Math]::Floor( ($t - $h*3600) / 60 )
            $s= [int][Math]::Floor( $t - $h*3600 -$m*60 )

            if ($h -gt 0)     {Write-Host "Run time: $h hours, $m minutes, $s seconds" -ForegroundColor Gray}
            elseif ($m -gt 0) {Write-Host "Run time: $m minutes, $s seconds" -ForegroundColor Gray}
            else              {Write-Host "Run time: $s seconds" -ForegroundColor Gray}
        } catch {}

        Write-Host "Finished synchronizing breakglass accounts in PAM to KeePassXC "
    }
}
