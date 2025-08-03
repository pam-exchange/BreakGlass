<#

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
function Backup-BreakglassAccounts {
    param (
        [Parameter(Mandatory=$false)][PAM_TYPE] $PAMType= "PasswordSafe",
        [Parameter(Mandatory=$false)][VAULT_TYPE] $VaultType= "KeePassXC",

        [Parameter(Mandatory=$false)][string] $ConfigPath= "c:\temp",

        [Parameter(Mandatory=$false)][switch] $Update= $false,

        [Parameter(Mandatory=$false)][switch] $Quiet= $false,
        [Parameter(Mandatory=$false)][switch] $WhatIf= $false
    )

    if ($WhatIf) {$quiet= $false}

    try {

        # 
        # Start-Breakglass will read configuration and 
        # start PasswordSafe and KeePassXC
        #
        Start-Breakglass -ConfigPath $ConfigPath -PAMType $PAMType -VaultType $VaultType 

        #
        # Fetch breakglass accounts from PAM
        #
        if (-not $Quiet) {Write-Host "Finding breakglass accounts from PAM" -ForegroundColor White}
        $pamAccounts= Get-BreakglassFromPAM -PAMType $PAMType -Quiet:$Quiet -WhatIf:$WhatIf
    
        if (-not $Quiet) {
            $pamAccounts | %{ Write-Host "$($_.server) | $($_.accountType) | $($_.accountName)" -ForegroundColor Gray }
            if ($pamAccounts.getType().Name -eq "PSCustomObject") {$cnt= 1} else {$cnt= $pamAccounts.count}
            Write-Host "Found '$cnt' breakglass accounts in PAM" -ForegroundColor Gray
        }

        #
        # Update passwords on breakglass accounts before backup
        #
        if ($update) {
            if (-not $Quiet) {Write-Host "Updating password on breakglass accounts in PAM" -ForegroundColor White}
            $res= Update-BreakGlassInPAM -PAMType $PAMType -Accounts $pamAccounts -Quiet:$Quiet -WhatIf:$WhatIf
        }


        #
        # Sync accounts from PAM with local Vault
        #
        if (-not $Quiet) {Write-Host "Aligning PAM accounts with KeePassXC" -ForegroundColor White}
        $res= Sync-BreakglassToVault -VaultType $VaultType -Accounts $pamAccounts -CreateDatabase -Quiet:$Quiet -WhatIf:$WhatIf

    } 
    catch {
        #Write-Host "$($_.Exception.Message) - $($_.Exception.Details)" -ForegroundColor Yellow
        #Write-Host $_.ScriptStackTrace -ForegroundColor Gray

        throw
    }
    finally {
        Stop-Breakglass
    }
}
