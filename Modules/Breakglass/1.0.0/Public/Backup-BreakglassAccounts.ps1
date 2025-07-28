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
        if (-not $Quiet) {Write-Host "Finding breakglass accounts from PAM"}
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
            if (-not $Quiet) {Write-Host "Updating password on breakglass accounts in PAM"}
            $res= Update-BreakGlassInPAM -PAMType $PAMType -Accounts $pamAccounts -Quiet:$Quiet -WhatIf:$WhatIf
        }


        #
        # Sync accounts from PAM with local Vault
        #
        if (-not $Quiet) {Write-Host "Aligning PAM accounts with KeePassXC"}
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
