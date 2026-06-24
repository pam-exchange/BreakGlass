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
function Sync-Breakglass {
    param (
        [Parameter(Mandatory=$false)][PAM_TYPE] $PAMType= "PasswordSafe",
        [Parameter(Mandatory=$false)][VAULT_TYPE] $VaultType= "KeePassXC",

        [Parameter(Mandatory=$false)][string] $ConfigPath= "c:\temp",

        [Parameter(Mandatory=$false)][switch] $Multiple= $false,
        [Parameter(Mandatory=$false)][switch] $Update= $false,

        [Parameter(Mandatory=$false)][switch] $Quiet= $false,
        [Parameter(Mandatory=$false)][switch] $WhatIf= $false
    )

    if ($WhatIf) {$quiet= $false}

    try {

        # 
        # Start-Breakglass will read configuration and start PAM and Vault
        #
        Start-Breakglass -ConfigPath $ConfigPath -PAMType $PAMType -VaultType $VaultType 

        #
        # Fetch breakglass accounts from PAM
        #
        if (-not $Quiet) {Write-Host "Finding breakglass accounts in '$PAMType'" -ForegroundColor White}
        $pamAccounts= Get-BreakglassFromPAM -PAMType $PAMType -Quiet:$Quiet -WhatIf:$WhatIf
    
        if (-not $Quiet) {
            $pamAccounts | %{ Write-Host "$($_.server) | $($_.accountType) | $($_.accountName)" -ForegroundColor Gray }
            if ($null -eq $pamAccounts) {$cnt= 0}
            elseif ($pamAccounts.getType().Name -eq "PSCustomObject") {$cnt= 1} else {$cnt= $pamAccounts.count}
            Write-Host "Found '$cnt' breakglass accounts in '$PAMType'" -ForegroundColor Gray
        }

        if ($cnt -eq 0) {
            #
            # Could be an error reading from PAM, but it is unexpected and
            # nothing further is done for now.
            #
            Write-Host "No accounts are found in '$PAMType'." -ForegroundColor Green
            Write-Host "This is unexpected and processing is stopped" -ForegroundColor Green
            Write-Host "If there really are no breakglass accounts in PAM, just delete the Vault database" -ForegroundColor gray
            return
        }


        #
        # Update passwords on breakglass accounts before backup
        #
        if ($update) {
            if ($pamAccounts) {
                if (-not $Quiet) {Write-Host "Updating password on breakglass accounts in '$PAMType'" -ForegroundColor White}
                $res= Update-BreakGlassInPAM -PAMType $PAMType -Accounts $pamAccounts -Quiet:$Quiet -WhatIf:$WhatIf
            }
            else {
                if (-not $Quiet) {Write-Host "No accounts to update" -ForegroundColor Gray}
            }
        }

        #
        # Fetch breakglass accounts from Vault
        #
        if (-not $Quiet) {Write-Host "Finding accounts in '$VaultType'" -ForegroundColor White}
        $vaultAccounts= Get-BreakglassFromVault -VaultType $VaultType -Multiple:$Multiple -Quiet:$Quiet -WhatIf:$WhatIf
        if (-not $Quiet) {
            $vaultAccounts | %{ Write-Host "$($_.title)" -ForegroundColor Gray }
            if ($null -eq $vaultAccounts) {$cnt=0}
            elseif ($vaultAccounts.getType().Name -eq "PSCustomObject") {$cnt= 1} else {$cnt= $vaultAccounts.count}
            Write-Host "Found '$cnt' breakglass accounts in '$VaultType'" -ForegroundColor Gray
        }
        
        #
        # Align accounts from PAM with local Vault
        #
        if (-not $Quiet) {Write-Host "Align '$PAMType' accounts with '$VaultType' database" -ForegroundColor White}
        $res= Sync-BreakglassWithVault -VaultType $VaultType -pamAccounts $pamAccounts -vaultAccounts $vaultAccounts -Multiple:$Multiple -Update:$Update -Quiet:$Quiet -WhatIf:$WhatIf
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
