<#----------------------------------------------------------------------------------
MIT License

Copyright (c) 2025 PAM-Exchange

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

#>

# ----------------------------------------------------------------------------------
param (
    [ValidateSet("PasswordSafe","SymantecPAM")]
    [Parameter(Mandatory=$false)][String] $PAMType= "PasswordSafe",
    [ValidateSet("KeePassXC")]
    [Parameter(Mandatory=$false)][String] $VaultType= "KeePassXC",
    [Parameter(Mandatory=$false)][string] $ConfigPath= "c:\temp",

    [Parameter(Mandatory=$false)][switch] $Single= $false,
    [Parameter(Mandatory=$false)][switch] $Update= $false,

    [Parameter(Mandatory=$false)][switch] $Quiet= $false,
    [Parameter(Mandatory=$false)][switch] $WhatIf= $false
)

try {$startTime= (Get-Date -ErrorAction SilentlyContinue)} catch {$now= 0}

$scriptBasePath= $PSScriptRoot
$scriptName= $PSCommandPath

#
# modulePath
#
if (-not $modulePath) {
    #$modulePath= $scriptBasePath.substring(0,$scriptBasePath.LastIndexOf("\"))
    $modulePath= $scriptBasePath
}

$Script:currentPSModulePath= $env:PSModulePath
if ($env:PSModulePath -notmatch ";"+$($modulePath.replace("\","\\"))+"\\modules") {
    $env:PSModulePath+=";$modulePath\modules"
}

if ($(Get-Module).name -contains "Breakglass") { Remove-Module Breakglass }
if ($(Get-Module).name -contains "KeePassXC") { Remove-Module KeePassXC }
if ($(Get-Module).name -contains "PasswordSafe") { Remove-Module PasswordSafe }
if ($(Get-Module).name -contains "SymantecPAM") { Remove-Module SymantecPAM }
if ($(Get-Module).name -contains "Logging") { Remove-Module Logging }

Import-Module Logging -Force
if ($PAMType -eq "PasswordSafe") { Import-Module PasswordSafe -Force }
if ($PAMType -eq "SymantecPAM") { Import-Module SymantecPAM -Force }
if ($VaultType -eq "KeePassXC") { Import-Module KeePassXC -Force }
Import-Module Breakglass -Force

# ----------------------------------------------------------------------------------
try {

    $modules= $(Get-Module).Name
    if ($modules -notcontains "Logging") { throw "Module Logging not available" }
    if ($modules -notcontains "Breakglass") { throw "Module Breakglass not available" }
    if ($VaultType -eq "KeePassXC" -and $modules -notcontains "KeePassXC") { throw "Module KeePassXC not available" }
    if ($PAMType -eq "SymantecPAM" -and $modules -notcontains "SymantecPAM") { throw "Module SymantecPAM not available" }
    if ($PAMType -eq "PasswordSafe" -and $modules -notcontains "PasswordSafe") { throw "Module PasswordSafe not available" }

    Sync-Breakglass -PAMType $PAMType -VaultType $VaultType -ConfigPath $ConfigPath -Single:$Single -Update:$Update -Quiet:$Quiet -WhatIf:$WhatIf

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

            $duration = if ($h -gt 0) { "$h hours, $m minutes, $s seconds" }
            elseif ($m -gt 0) { "$m minutes, $s seconds" }
            else { "$s seconds" }

            Write-Host "Run time: $duration" -ForegroundColor White

        } catch {}

        Write-Host "Finished aligning '$PAMType' accounts with '$VaultType' database" -ForegroundColor White
    }
}

# -- end-of-file ---