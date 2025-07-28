function New-KeePassXCEntry {
    param (
        [Parameter(Mandatory=$false)][string] $DatabasePath= $Script:kpDatabasePath,
        [Parameter(Mandatory=$false)][string] $KeyFilePath= $Script:kpKeyFilePath,
        [Parameter(Mandatory=$false)][string] $MasterPassword= $Script:kpMasterPassword,
        [Parameter(Mandatory=$false)][string] $Group,

        [Parameter(Mandatory=$true)][string] $Title,
        [Parameter(Mandatory=$true)][string] $Username,
        [Parameter(Mandatory=$true)][string] $Password,
        [Parameter(Mandatory=$false)][switch] $Verified= $false,
		
        [Parameter(Mandatory=$false)][switch] $Quiet= $false,
        [Parameter(Mandatory=$false)][switch] $WhatIf= $false
    )

    if (-not $Script:kpInitialized) {
        $msg= "KeePassXC module is not initialized"
        if (-not $Quiet -or $WhatIf) {Write-Host $msg -ForegroundColor Yellow}
        throw ( New-Object KeePassXCException( $EXCEPTION_INITIALIZE, $msg))
    }

    if ($Password -match "-----") {
        # unlikely that a generated passwords contains 5 -
        $notes= $password
        $password= "SSH Private Key"
    }
    else {
        if ($Verified) {$notes= "Password is verified"} 
        else {$notes= "Password is not verified"}
    }

    if ($KeyFilePath) {
		$msg= $MasterPassword+"`n"+$Password | keepassxc-cli add --password-prompt --username $Username --notes $notes --key-file $KeyFilePath $DatabasePath "$Group/$title" 2>&1
	} else {
		$msg= $MasterPassword+"`n"+$Password | keepassxc-cli add --password-prompt --username $Username --notes $notes $DatabasePath "$Group/$title" 2>&1
	}
    return Test-Message($msg)
}
