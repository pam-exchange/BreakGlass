<#----------------------------------------------------------------------------------

This script will extract breakglass accounts from PAM and store them in KeePassXC.

-------------
History

1.1.0 - 2025-08-04 - Added PasswordSafe
                   - Update allowing different PAM
1.0.0 - 2018-03-27 - First release
--------------------------------------------------------------

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
    [ValidateSet("PasswordSafe", "SymantecPAM")]
    [Parameter(Mandatory = $false)]
    [String] $PAMType = "PasswordSafe",

    [ValidateSet("KeePassXC")]
    [Parameter(Mandatory = $false)]
    [String] $VaultType = "KeePassXC",

    [Parameter(Mandatory = $false)]
    [string] $ConfigPath = "c:\temp",

    [Parameter(Mandatory = $false)]
    [switch] $Multiple = $false,

    [Parameter(Mandatory = $false)]
    [switch] $Update = $false,

    [Parameter(Mandatory = $false)]
    [switch] $Quiet = $false,

    [Parameter(Mandatory = $false)]
    [switch] $WhatIf = $false
)

try { $startTime = (Get-Date -ErrorAction SilentlyContinue) } catch { $now = 0 }

$version = "1.1.0"

#
# modulePath
#
$moduleRoot = Join-Path $PSScriptRoot "Modules"

if (Test-Path $moduleRoot) {
    if ($env:PSModulePath -notmatch [regex]::Escape($moduleRoot)) {
        $env:PSModulePath = "$moduleRoot;$env:PSModulePath"
    }
}

# Clear existing modules to ensure fresh import
"Breakglass", "KeePassXC", "PasswordSafe", "SymantecPAM", "Logging" | ForEach-Object {
    if (Get-Module -Name $_) { Remove-Module -Name $_ }
}

# Import required modules
Import-Module Logging -Force
if ($PAMType -eq "PasswordSafe") { Import-Module PasswordSafe -Force }
if ($PAMType -eq "SymantecPAM") { Import-Module SymantecPAM -Force }
if ($VaultType -eq "KeePassXC") { Import-Module KeePassXC -Force }
Import-Module Breakglass -Force

# ----------------------------------------------------------------------------------
try {
    Sync-Breakglass -PAMType $PAMType -VaultType $VaultType -ConfigPath $ConfigPath -Multiple:$Multiple -Update:$Update -Quiet:$Quiet -WhatIf:$WhatIf
}
catch {
    Write-Log -Message "Exception: $($_.Exception.GetType().FullName)`nMessage: $($_.Exception.Message)`nDetails: $($_.Exception.Details)" -Level Error -Quiet:$Quiet
    Write-Log -Message $_.ScriptStackTrace -Level Debug -Quiet:$Quiet
}
finally {
    if (-not $Quiet -or $WhatIf) {
        try {
            # --- Elapsed time ---
            $t = [int]((Get-Date -ErrorAction SilentlyContinue) - $startTime).TotalSeconds

            $h = [int][Math]::Floor($t / 3600)
            $m = [int][Math]::Floor(($t - $h * 3600) / 60)
            $s = [int][Math]::Floor($t - $h * 3600 - $m * 60)

            $duration = if ($h -gt 0) { "$h hours, $m minutes, $s seconds" }
            elseif ($m -gt 0) { "$m minutes, $s seconds" }
            else { "$s seconds" }

            Write-Log -Message "Run time: $duration" -Level Info -Quiet:$Quiet
        } catch {}

        Write-Log -Message "Finished aligning '$PAMType' accounts with '$VaultType' database" -Level Info -Quiet:$Quiet
    }
}

# -- end-of-file ---
