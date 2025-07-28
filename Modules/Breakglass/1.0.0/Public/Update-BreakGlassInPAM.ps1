<#
This function will synchronize or align information from PAM
with a KeePassXC database

#>


function Update-BreakglassInPAM {
    param (

        [Parameter(Mandatory=$false)][PAM_TYPE] $PAMType = "PasswordSafe",

        [Parameter(Mandatory=$true)][Object[]] $Accounts,
        [Parameter(Mandatory=$false)][string] $Password,

        [Parameter(Mandatory=$false)][switch] $Quiet= $false,
        [Parameter(Mandatory=$false)][switch] $WhatIf= $false
    )

    switch ($PAMType) {
        "PasswordSafe" 
        {
            $res= Update-BreakGlassInPasswordSafe -Accounts $Accounts -Password $Password -Quiet:$Quiet -WhatIf:$WhatIf
        }

        "SymantecPAM" 
        {
            $res= Update-BreakGlassInSymantecPAM -Accounts $Accounts -Password $Password -Quiet:$Quiet -WhatIf:$WhatIf
        }
    }
}

# --- end-of-file ---