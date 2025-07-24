# ----------------------------------------------------------------------------------
function Backup-BreakglassAccounts {
    param (
        [Parameter(Mandatory=$false)][PAM_TYPE] $PAMType= "PasswordSafe",
        [Parameter(Mandatory=$false)][VAULT_TYPE] $VaultType= "KeePassXC",
        [Parameter(Mandatory=$false)][string] $ConfigPath= "c:\temp",

        [Parameter(Mandatory=$false)][switch] $Quiet= $false,
        [Parameter(Mandatory=$false)][switch] $WhatIf= $false
    )

    try {

        # 
        # Start-Breakglass will read configuration and 
        # start PasswordSafe and KeePassXC
        #
        Start-Breakglass -ConfigPath $ConfigPath -PAMType $PAMType -VaultType $VaultType 

        #
        # Fetch breakglass accounts from PAM
        #
        if (-not $Quiet -or $WhatIf) {Write-Host "Fetching breakglass accounts from PAM"}
        $pamAccounts= Find-BreakglassFromPAM -PAMType $PAMType -Quiet:$Quiet -WhatIf:$WhatIf
    
        if (-not $Quiet -or $WhatIf) {Write-Host "Found $($pamAccounts.count) breakglass accounts in PAM" -ForegroundColor Gray}

        #
        # Sync accounts from PAM with local Vault
        #
        if (-not $Quiet -or $WhatIf) {Write-Host "Aligning PAM accounts with KeePassXC"}
        $res= Sync-BreakglassToVault -VaultType $VaultType -BreakGlassEntries $pamAccounts -CreateDatabase -Quiet:$Quiet -WhatIf:$WhatIf

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
