<#
This function will synchronize or align information from PAM
with a KeePassXC database

#>


function Update-BreakglassInSymantecPAM {
    param (
        [Parameter(Mandatory=$true)][Object[]] $Accounts,
        [Parameter(Mandatory=$false)][string] $Password,

        [Parameter(Mandatory=$false)][switch] $Quiet= $false,
        [Parameter(Mandatory=$false)][switch] $WhatIf= $false
    )

    if ($WhatIf) {$quiet= $false}

    foreach ($acc in $Accounts) {
        try {
            if ($WhatIf) {Write-Host "WhatIf: " -ForegroundColor Green -NoNewline}
            if (-not $Quiet) {Write-Host "$($acc.Server) | $($acc.accountType) | $($acc.accountName) -- " -NoNewline -ForegroundColor Gray }

            if (-not $WhatIf) {
                $res= Update-SymTargetAccountPassword -AccountID $acc.accountID -Password $Password
            }
        } 
        catch {
            if (-not $Quiet) {Write-Host "Password not updated" -ForegroundColor Yellow}
            continue
        }

        if (-not $Quiet) {Write-Host "Password updated" -ForegroundColor Green}

        $pwd= Get-SymTargetAccountPassword -AccountID $acc.accountID
        $acc.accountpassword= $pwd
    }
}

# --- end-of-file ---