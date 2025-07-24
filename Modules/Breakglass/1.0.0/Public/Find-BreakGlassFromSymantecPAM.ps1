<#
This function will lookup breakglass accounts in PAM (Password Safe), fetch the 
password and return a list of entries

#>
# ------------------------------------------------------------------------------------
function Find-BreakglassFromSymantecPAM {
    param (
        [Parameter(Mandatory=$false)][switch]$Quiet= $false,
        [Parameter(Mandatory=$false)][switch]$WhatIf= $false
    )

    $WhatIf= $false

    $list= New-Object System.Collections.ArrayList

    try {
        $accounts= Get-SPTargetAccount

        foreach ($acc in $accounts) {
            $pwd= Get-SPTargetAccountPassword -AccountID $acc.TargetAccountID

            $list.add( [PSCustomObject]@{server=$($acc.TargetServerName); accountType=$($acc.TargetApplicationName); accountName=$($acc.TargetAccountName); accountPassword=$pwd} ) | Out-Null
        }
    } 
    catch {
        throw
    }

    return $list
}

# --- end-of-file ---