function Get-KeePassXCEntry {
    param (
        [Parameter(Mandatory=$false)][string]$DatabasePath= $Script:kpDatabasePath,
        [Parameter(Mandatory=$false)][string]$KeyFilePath= $Script:kpKeyFilePath,
        [Parameter(Mandatory=$false)][string]$MasterPassword= $Script:kpMasterPassword,
        [Parameter(Mandatory=$false)][string]$Group,
        [Parameter(Mandatory=$false)][string]$Title,
		
        [Parameter(Mandatory=$false)][switch]$Quiet= $false,
        [Parameter(Mandatory=$false)][switch]$WhatIf= $false
    )
    if (-not $Script:kpInitialized) {
        $msg= "KeePassXC module is not initialized"
        if (-not $Quiet -or $WhatIf) {Write-Host $msg -ForegroundColor Yellow}
        throw ( New-Object KeePassXCException( $EXCEPTION_INITIALIZE, $msg))
    }

    if ($Title) {
        #
        # Fetch one entry
        #
		if ($KeyFilePath) {
			$e= $MasterPassword | keepassxc-cli show --attributes Title --attributes UserName --attributes Password --key-file $KeyFilePath $DatabasePath "$Group/$Title" 2>&1
		} else {
			$e= $MasterPassword | keepassxc-cli show --attributes Title --attributes UserName --attributes Password $DatabasePath "$Group/$Title" 2>&1
		}

        if ($e.length -ne 4) {
            # Array with length 4 is expected
            Test-Message($e)
        }

        return [PSCustomObject]@{title=$e[1]; username=$e[2]; password=$e[3]}
    }

    #
    # Fetch all entries in Group
    #
    $entries= New-Object System.Collections.ArrayList

    # 
    # If the group is empty the list returned is everything from KeePassXC
    # this cludes groups, entries from groups, and empth
    # ignore all except entries from root level
    #
	if ($KeyFilePath) {
		$list= $MasterPassword | keepassxc-cli ls --key-file $KeyFilePath $DatabasePath $Group 2> $null | Where-Object {$_ -notmatch "\[empty\]|.*/$|^ "}
	} else {
		$list= $MasterPassword | keepassxc-cli ls $DatabasePath $Group 2> $null | Where-Object {$_ -notmatch "\[empty\]|.*/$|^ "}
	}

	# TO-DO: Error handling, invalid parameters

    foreach ($t in $list) {
		if ($KeyfilePath) {
			$e= $MasterPassword | keepassxc-cli show --attributes Title --attributes UserName --attributes Password --key-file $KeyFilePath $DatabasePath "$Group/$t" 2>&1
		} else {
			$e= $MasterPassword | keepassxc-cli show --attributes Title --attributes UserName --attributes Password $DatabasePath "$Group/$t" 2>&1
		}

        if ($e.length -ne 4) {
            # Array with length 4 is expected
            Test-Message($e)
        }

        $entries.Add([PSCustomObject]@{title=$e[1]; username=$e[2]; password=$e[3]}) | Out-Null
    }

    return $entries
}
