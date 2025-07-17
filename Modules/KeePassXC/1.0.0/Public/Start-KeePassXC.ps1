#--------------------------------------------------------------------------------------
function Start-KeePassXC {
	Param (
		[Parameter(Mandatory=$true)][string]$DatabasePath,
		[Parameter(Mandatory=$true)][string]$KeyFilePath,
		[Parameter(Mandatory=$true)][string]$MasterPassword,
		[Parameter(Mandatory=$true)][string]$Group,
		
        [Parameter(Mandatory=$false)][switch]$Quiet= $false,
        [Parameter(Mandatory=$false)][switch]$WhatIf= $false
	)

	$Script:kpDatabasePath= $databasePath
	$script:kpKeyFilePath= $KeyFilePath
	$Script:kpGroup= $Group
	$Script:kpMasterPassword= $MasterPassword
    $Script:kpInitialized= $true
}

# --- end-of-file ---