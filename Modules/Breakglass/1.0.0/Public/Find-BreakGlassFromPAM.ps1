<#
This function will lookup breakglass accounts in PAM (Password Safe), fetch the 
password and return a list of entries

#>


# ------------------------------------------------------------------------------------
function Find-BreakglassFromPAM {
    param (
        [Parameter(Mandatory=$false)][PAM_TYPE] $PAMType= "PasswordSafe",

        [Parameter(Mandatory=$false)][switch] $Quiet= $false,
        [Parameter(Mandatory=$false)][switch] $WhatIf= $false
    )

    $WhatIf= $false

    switch ($PAMType) {
        "PasswordSafe" {
            return Find-BreakglassFromPasswordSafe -Quiet:$Quiet -WhatIf:$WhatIf
            }
    }
}

# --- end-of-file ---