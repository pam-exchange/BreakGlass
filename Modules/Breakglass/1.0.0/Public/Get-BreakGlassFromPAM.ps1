<#
This function will lookup breakglass accounts in PAM (Password Safe), fetch the 
password and return a list of entries

#>


# ------------------------------------------------------------------------------------
function Get-BreakglassFromPAM {
    param (
        [Parameter(Mandatory=$false)][PAM_TYPE] $PAMType= "PasswordSafe",

        [Parameter(Mandatory=$false)][switch] $Quiet= $false,
        [Parameter(Mandatory=$false)][switch] $WhatIf= $false
    )

    if ($WhatIf) {$quiet= $false}

    switch ($PAMType) 
    {
        "PasswordSafe" 
        {
            return Get-BreakglassFromPasswordSafe -Quiet:$Quiet -WhatIf:$WhatIf
        }
        "SymantecPAM" 
        {
            return Get-BreakglassFromSymantecPAM -Quiet:$Quiet -WhatIf:$WhatIf
        }
    }
}

# --- end-of-file ---