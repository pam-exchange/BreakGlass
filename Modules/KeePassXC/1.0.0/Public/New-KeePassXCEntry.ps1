function New-KeePassXCEntry {
    param (
        [Parameter(Mandatory=$false)][string]$DatabasePath= $Script:kpDatabasePath,
        [Parameter(Mandatory=$false)][string]$KeyFilePath= $Script:kpKeyFilePath,
        [Parameter(Mandatory=$false)][string]$MasterPassword= $Script:kpMasterPassword,
        [Parameter(Mandatory=$false)][string]$Group,

        [Parameter(Mandatory=$true)][string]$Title,
        [Parameter(Mandatory=$true)][string]$Username,
        [Parameter(Mandatory=$true)][string]$Password,
		
        [Parameter(Mandatory=$false)][switch]$Quiet= $false,
        [Parameter(Mandatory=$false)][switch]$WhatIf= $false
    )

    if (-not $Script:kpInitialized) {
        $msg= "KeePassXC module is not initialized"
        if (-not $Quiet -or $WhatIf) {Write-Host $msg -ForegroundColor Yellow}
        throw ( New-Object KeePassXCException( $EXCEPTION_INITIALIZE, $msg))
    }

    $msg= $MasterPassword+"`n"+$Password | keepassxc-cli add --password-prompt --username $Username --key-file $KeyFilePath $DatabasePath "$Group/$title" 2>&1
    return Test-Message($msg)
}
