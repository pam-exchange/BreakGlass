function New-KeePassXCDatabase {
    param (
        [Parameter(Mandatory=$false)][string]$DatabasePath= $Script:kpDatabasePath,
        [Parameter(Mandatory=$false)][string]$KeyFilePath= $Script:kpKeyFilePath,
        [Parameter(Mandatory=$false)][string]$MasterPassword= $Script:kpMasterPassword,

        [Parameter(Mandatory=$false)][switch]$Quiet= $false,
        [Parameter(Mandatory=$false)][switch]$WhatIf= $false
    )

    if (-not $Quiet -or -$WhatIf) {
        Write-Host "Creating database '$DatabasePath'" -ForegroundColor Green
    }

	if ($KeyFilePath) {
		$msg= $MasterPassword+"`n"+$MasterPassword | keepassxc-cli db-create --set-key-file $KeyFilePath --set-password $DatabasePath 2>&1
	} else {
		$msg= $MasterPassword+"`n"+$MasterPassword | keepassxc-cli db-create --set-password $DatabasePath 2>&1
	}
    return Test-Message($msg)
}
