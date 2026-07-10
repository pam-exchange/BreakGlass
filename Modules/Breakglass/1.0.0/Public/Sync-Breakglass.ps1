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

        [Parameter(Mandatory=$false)][switch] $Single= $false,
        [Parameter(Mandatory=$false)][switch] $Update= $false,

        [Parameter(Mandatory=$false)][switch] $Quiet= $false,
        [Parameter(Mandatory=$false)][switch] $WhatIf= $false
    )

    if ($WhatIf) { $Quiet = $false }

    try {

        # 
        # Start-Breakglass will read configuration and start PAM and Vault
        #
        Start-Breakglass -ConfigPath $ConfigPath -PAMType $PAMType -VaultType $VaultType 

        #
        # Fetch breakglass accounts from PAM
        #
        if (-not $Quiet) { Write-Log "Finding breakglass accounts in '$PAMType'" -Level Success }
        $PamAccounts = Get-BreakglassFromPAM -PAMType $PAMType -Quiet:$Quiet -WhatIf:$WhatIf
    
        if (-not $Quiet) {
            $PamAccounts | ForEach-Object { Write-Log "$($_.server) | $($_.accountType) | $($_.accountName)" -Level Debug }
            if ($null -eq $PamAccounts) { $cnt = 0 }
            elseif ($PamAccounts.GetType().Name -eq "PSCustomObject") { $cnt = 1 } else { $cnt = $PamAccounts.Count }
            Write-Log "Found '$cnt' breakglass accounts in '$PAMType'" -Level Debug
        }

        if ($cnt -eq 0) {
            #
            # Could be an error reading from PAM, but it is unexpected and
            # nothing further is done for now.
            #
            Write-Log "No accounts are found in '$PAMType'." -Level Warning
            Write-Log "This is unexpected and processing is stopped" -Level Warning
            Write-Log "If there really are no breakglass accounts in PAM, just delete the Vault database" -Level Warning
            return
        }


        #
        # Update passwords on breakglass accounts before backup
        #
        if ($Update) {
            if ($PamAccounts) {
                if (-not $Quiet) { Write-Log "Updating password on breakglass accounts in '$PAMType'" -Level Success }
                $res = Update-BreakglassInPAM -PAMType $PAMType -Accounts $PamAccounts -Quiet:$Quiet -WhatIf:$WhatIf
            }
            else {
                if (-not $Quiet) { Write-Log "No accounts to update" -Level Debug }
            }
        }

        #
        # Fetch breakglass accounts from Vault
        #
        if (-not $Quiet) { Write-Log "Finding accounts in '$VaultType'" -Level Success }
        $VaultAccounts = Get-BreakglassFromVault -VaultType $VaultType -Single:$Single -Quiet:$Quiet -WhatIf:$WhatIf
        if (-not $Quiet) {
            $VaultAccounts | ForEach-Object { Write-Log "$($_.title)" -Level Debug }
            if ($null -eq $VaultAccounts) { $cnt = 0 }
            elseif ($VaultAccounts.GetType().Name -eq "PSCustomObject") { $cnt = 1 } else { $cnt = $VaultAccounts.Count }
            Write-Log "Found '$cnt' breakglass accounts in '$VaultType'" -Level Debug
        }
        
        #
        # Align accounts from PAM with local Vault
        #
        if (-not $Quiet) { Write-Log "Align '$PAMType' accounts with '$VaultType' database" -Level Success }
        $res = Sync-BreakglassWithVault -VaultType $VaultType -pamAccounts $PamAccounts -vaultAccounts $VaultAccounts -Single:$Single -Update:$Update -Quiet:$Quiet -WhatIf:$WhatIf
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
