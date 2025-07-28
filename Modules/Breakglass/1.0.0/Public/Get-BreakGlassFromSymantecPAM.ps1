<#
This function will lookup breakglass accounts in PAM (Symantec PAM), fetch the 
password and return a list of entries

Exceptions may be thrown by underlying methods

#>
# ------------------------------------------------------------------------------------
function Get-BreakglassFromSymantecPAM {
    param (
        [Parameter(Mandatory=$false)][switch] $Quiet= $false,
        [Parameter(Mandatory=$false)][switch] $WhatIf= $false
    )

    if ($WhatIf) {$quiet= $false}

    $list= New-Object System.Collections.ArrayList

    $accounts= Get-SymTargetAccount

    foreach ($acc in $accounts) {
        $pwd= Get-SymTargetAccountPassword -AccountID $acc.TargetAccountID

        $list.add( [PSCustomObject]@{
                            server=$($acc.TargetServerName); 
                            accountType=$($acc.TargetApplicationName); 
                            accountID= $($acc.TargetAccountID); 
                            accountName=$($acc.TargetAccountName); 
                            accountPassword=$pwd; 
                            verified=$($acc.Verified)} 
                 ) | Out-Null
    }

    return $list
}

# --- end-of-file ---