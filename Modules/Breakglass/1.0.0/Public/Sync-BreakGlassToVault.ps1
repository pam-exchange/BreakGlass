<#
This function will synchronize or align information from PAM
with a KeePassXC database

#>

enum VAULT_TYPE {
	KeePassXC
}


function Sync-BreakglassToVault {
    param (

        [Parameter(Mandatory=$false)][VAULT_TYPE]$VaultType = "KeePassXC",

        [Parameter(Mandatory=$false)][switch]$CreateDatabase= $false,
        [Parameter(Mandatory=$true)][Object[]]$BreakGlassEntries,

        [Parameter(Mandatory=$false)][switch]$Quiet= $false,
        [Parameter(Mandatory=$false)][switch]$WhatIf= $false
    )

    switch ($VaultType) {
        "KeePassXC" {
            return Sync-BreakglassToKeePassXC -BreakGlassEntries $BreakGlassEntries -CreateDatabase -Quiet:$Quiet -WhatIf:$WhatIf
            }
    }


}

# --- end-of-file ---