<#
This function will synchronize or align information from PAM
with a KeePassXC database

#>


function Sync-BreakglassToVault {
    param (

        [Parameter(Mandatory=$false)][VAULT_TYPE] $VaultType = "KeePassXC",

        [Parameter(Mandatory=$false)][switch] $CreateDatabase= $false,
        [Parameter(Mandatory=$true)][Object[]] $Accounts,

        [Parameter(Mandatory=$false)][switch] $Quiet= $false,
        [Parameter(Mandatory=$false)][switch] $WhatIf= $false
    )

    if ($WhatIf) {$quiet= $false}

    switch ($VaultType) {
        "KeePassXC" 
        {
            return Sync-BreakglassToKeePassXC -Accounts $Accounts -CreateDatabase -Quiet:$Quiet -WhatIf:$WhatIf
        }
    }


}

# --- end-of-file ---