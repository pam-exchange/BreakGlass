function Test-KeePassXCGroup {
    param (
        [Parameter(Mandatory=$false)][string]$DatabasePath= $Script:kpDatabasePath,
        [Parameter(Mandatory=$false)][string]$KeyFilePath= $Script:kpKeyFilePath,
        [Parameter(Mandatory=$false)][string]$MasterPassword= $Script:kpMasterPassword,
        [Parameter(Mandatory=$true)][string]$Group,
		
        [Parameter(Mandatory=$false)][switch]$Quiet= $false,
        [Parameter(Mandatory=$false)][switch]$WhatIf= $false
    )

    if (-not $Script:kpInitialized) {
        $msg= "KeePassXC module is not initialized"
        if (-not $Quiet -or $WhatIf) {Write-Host $msg -ForegroundColor Yellow}
        throw ( New-Object KeePassXCException( $EXCEPTION_INITIALIZE, $msg))
    }

    #
    # Using "ls" without a group name will return a list of entries at root level
    # Group names are with suffix "/"
    #
	if ($KeyFilePath) {
		$msg= $MasterPassword | keepassxc-cli ls --key-file $KeyFilePath $DatabasePath 2>&1
	} else {
		$msg= $MasterPassword | keepassxc-cli ls $DatabasePath 2>&1
	}

    #
    # First test if there is an error
    # in parameters calling keepassxc-cli
    # These are invalid password, invalid keyfile or invalid database
    #        
    if ($msg -imatch "Invalid credentials|Failed to") {
        return Test-Message($msg)
    }

    #
    # No  errors found, check if the 
    # group name (case sensitive) is found
    #
    return $msg -ccontains "$Group/"
}
