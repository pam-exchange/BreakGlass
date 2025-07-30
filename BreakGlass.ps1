<#------------------------------------------------------------

This script will extract breakglass accounts from BeyondTrust Password Safe
and store them in KeePassXC.

-------------
History

1.0.0 - 2025-07-xx - First release
------------------------------------------------------------
#>

# ----------------------------------------------------------------------------------
param (
    [ValidateSet("PasswordSafe","SymantecPAM")]
    [Parameter(Mandatory=$false)][String] $PAMType= "SymantecPAM",
    [ValidateSet("KeePassXC")]
    [Parameter(Mandatory=$false)][String] $VaultType= "KeePassXC",
    [Parameter(Mandatory=$false)][string] $ConfigPath= "c:\temp",

    [Parameter(Mandatory=$false)][switch] $Update= $false,

    [Parameter(Mandatory=$false)][switch] $Quiet= $false,
    [Parameter(Mandatory=$false)][switch] $WhatIf= $false
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
if ($(Get-Module).name -contains "SymantecPAM") { Remove-Module SymantecPAM }


if ($PAMType -eq "PasswordSafe") { Import-Module PasswordSafe -Force }
if ($PAMType -eq "SymantecPAM") { Import-Module SymantecPAM -Force }
Import-Module KeePassXC -Force
Import-Module Breakglass -Force

# ----------------------------------------------------------------------------------
try {

    Backup-BreakglassAccounts -PAMType $PAMType -VaultType $VaultType -ConfigPath $ConfigPath -Update:$Update -Quiet:$Quiet -WhatIf:$WhatIf

} 
catch {
    Write-Host "Exception: $($_.Exception.GetType().FullName)`nMessage: $($_.Exception.Message)`nDetails: $($_.Exception.Details)" -ForegroundColor Yellow
    Write-Host $_.ScriptStackTrace -ForegroundColor Gray
}
finally {
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

# -- end-of-file ---