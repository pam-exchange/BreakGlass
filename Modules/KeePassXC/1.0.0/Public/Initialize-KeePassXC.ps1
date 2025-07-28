function Initialize-KeePassXC {
    param (
        [Parameter(Mandatory=$true)][string]$DatabasePath,
        [Parameter(Mandatory=$false)][string]$KeyFilePath,
        [Parameter(Mandatory=$true)][string]$MasterPassword,
        [Parameter(Mandatory=$false)][string]$KeyPassProgram= "c:\program files\Keepassxc\keepassxc-cli.exe",
        [Parameter(Mandatory=$false)][switch]$CreateDatabase= $false,
		
        [Parameter(Mandatory=$false)][switch]$Quiet= $false,
        [Parameter(Mandatory=$false)][switch]$WhatIf= $false
    )

    if (Test-Path -Path $KeyPassProgram) {
        # KeePassXC-cli.exe is found
        #
        # Verify that it is available in system path
        # If not found in Path, update path
        #
        $KeyPassExec= Split-Path $KeyPassProgram -Leaf
        if ((Get-Command $KeyPassExec -ErrorAction SilentlyContinue) -eq $null) { 
            $KeyPassPath= Split-Path $KeyPassProgram -Parent

            if ($env:Path -notcontains $KeyPassPath) {
                if (-not $Quiet) {Write-Host "Adding '$KeyPassPath' to PATH" -ForegroundColor Gray}
                $env:Path= $env:Path+";"+$keyPassPath
            }
        }
    }
    else {
        # KeePassXC-cli program not found
        $msg= "keepassxc-cli.exe is not found"
        if (-not $Quiet) {Write-Host $msg -ForegroundColor Yellow}
        throw ( New-Object KeePassXCException( $EXCEPTION_NOT_FOUND, $msg))
    }

    if (-not $CreateDatabase) {
        #
        # database and key file must exist
        #
        if (-not (Test-Path -Path $DatabasePath)) {
            $msg= "Database file is not found '$DatabasePath'"
            if (-not $Quiet) {Write-Host $msg -ForegroundColor Yellow}
            throw ( New-Object KeePassXCException( $EXCEPTION_NOT_FOUND, $msg))
        }

        if ($KeyFilePath -and -not (Test-Path -Path $KeyFilePath)) {
            $msg= "Key file is not found '$KeyfilePath'"
            if (-not $Quiet) {Write-Host $msg -ForegroundColor Yellow}
            throw ( New-Object KeePassXCException( $EXCEPTION_NOT_FOUND, $msg))
        }
    }


    if ($createDatabase -and (-not (Test-Path -Path $DatabasePath) -or ($KeyFilePath -and -not (Test-Path -Path $KeyFilePath)) )) {
        # 
        # Either database or keyfile (or both) is missing, remove the other
        # Create new database
        #
        if (Test-Path -Path $DatabasePath) {
            try {
                if ($WhatIf) {
                    Write-Host "WhatIf: Removing database file '$DatabasePath'" -ForegroundColor Gray
                }
                else {
                    if (-not $Quiet) {Write-Host "Remove existing database file '$DatabasePath'" -ForegroundColor Gray}
                    Remove-Item -Path $DatabasePath -ErrorAction Stop
                }
            }
            catch {
                $msg= "Insufficient permissions to remove file '$DatabasePath'"
                throw ( New-Object KeePassXCException( $EXCEPTION_NOT_AUTHORIZED, $msg))
            }
        }
        else 
        {
            $checkPath= Split-Path $DatabasePath -Parent
            if (-not (Test-Path -Path $checkPath)) {
                $msg= "The path specified is not found '$DatabasePath'"
                if (-not $Quiet) {Write-Host $msg -ForegroundColor Yellow}
                throw ( New-Object KeePassXCException( $EXCEPTION_NOT_FOUND, $msg))
            }
        }

		if ($KeyFilePath) {
			if (Test-Path -Path $KeyFilePath) {
				try {
					if ($WhatIf) {
						Write-Host "WhatIf: Removing KeyFile '$KeyFilePath'" -ForegroundColor Gray
					}
					else {
						if (-not $Quiet) {Write-Host "Remove existing key file '$KeyFilePath'" -ForegroundColor Gray}
						Remove-Item -Path $KeyFilePath -ErrorAction Stop
					}
				}
				catch {
					$msg= "Insufficient permissions to remove file '$KeyFilePath'"
					throw ( New-Object KeePassXCException( $EXCEPTION_NOT_AUTHORIZED, $msg))
				}
			}
			else 
			{
				$checkPath= Split-Path $KeyFilePath -Parent        
				if (-not (Test-Path -Path $checkPath)) {
					$msg= "The path specified is not found '$KeyFilePath'"
					if ($Verbose) {Write-Host $msg -ForegroundColor Yellow}
					throw ( New-Object KeePassXCException( $EXCEPTION_NOT_FOUND, $msg))
				}
			}
			$res= New-KeePassXCDatabase -DatabasePath $DatabasePath -KeyFilePath $KeyFilePath -MasterPassword $MasterPassword -Quiet:$Quiet -WhatIf:$WhatIf
		} else {
			$res= New-KeePassXCDatabase -DatabasePath $DatabasePath -MasterPassword $MasterPassword -Quiet:$Quiet -WhatIf:$WhatIf
		}
    }

    $Script:kpDatabasePath= $DatabasePath
    $Script:kpKeyFilePath= $KeyFilePath
    $Script:kpMasterPassword= $MasterPassword
    $Script:kpKeePassProgram= $KeypassProgram
    $Script:kpInitialized= $true
}

# --- end-of-file ---