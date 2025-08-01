function Remove-KeePassXCGroup {
    param (
        [Parameter(Mandatory=$false)][string]$DatabasePath= $Script:kpDatabasePath,
        [Parameter(Mandatory=$false)][string]$KeyFilePath= $Script:kpKeyFilePath,
        [Parameter(Mandatory=$false)][string]$MasterPassword= $Script:kpMasterPassword,
        [Parameter(Mandatory=$false)][string]$Group,
		
        [Parameter(Mandatory=$false)][switch]$Quiet= $false,
        [Parameter(Mandatory=$false)][switch]$WhatIf= $false
    )

    if (-not $Script:kpInitialized) {
        $msg= "KeePassXC module is not initialized"
        if (-not $Quiet -or $WhatIf) {Write-Host $msg -ForegroundColor Yellow}
        throw ( New-Object KeePassXCException( $EXCEPTION_INITIALIZE, $msg))
    }

    if ($KeyPassPath) {
		$msg= $MasterPassword | keepassxc-cli rmdir --key-file $KeyFilePath $DatabasePath $Group 2>&1
	} else {
		$msg= $MasterPassword | keepassxc-cli rmdir $DatabasePath $Group 2>&1
	}

	return Test-Message($msg)
}
