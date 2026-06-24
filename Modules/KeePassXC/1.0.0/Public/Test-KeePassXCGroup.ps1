<#
MIT License

Copyright (c) 2025 PAM-Exchange

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

#>
#--------------------------------------------------------------------------------------
function Test-KeePassXCGroup {
    param (
        [Parameter(Mandatory=$false)][string]$DatabaseFilename= $Script:kpDatabaseFilename,
        [Parameter(Mandatory=$false)][string]$KeyFileFilename= $Script:kpKeyFileFilename,
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
	if ($KeyFileFilename) {
		$msg= $MasterPassword | keepassxc-cli ls --key-file $KeyFileFilename $DatabaseFilename 2>&1
	} else {
		$msg= $MasterPassword | keepassxc-cli ls $DatabaseFilename 2>&1
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
    $Group= $Group.Trim("/")
    if ($msg -cmatch "^$Group/$") {
        return $true
    } 
    else {
        return $false
    }
}
