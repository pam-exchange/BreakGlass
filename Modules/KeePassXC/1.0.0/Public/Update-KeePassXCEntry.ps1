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
function Update-KeePassXCEntry {
    param (
        [Parameter(Mandatory=$false)][string] $DatabaseFilename= $Script:kpDatabaseFilename,
        [Parameter(Mandatory=$false)][string] $KeyFileFilename= $Script:kpKeyFileFilename,
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

	if ($KeyFileFilename) {
		$msg= $MasterPassword+"`n"+$Password | keepassxc-cli edit --password-prompt --username $username --notes $notes --key-file $KeyFileFilename $DatabaseFilename "$Group/$title" 2>&1
	}
	else {
		$msg= $MasterPassword+"`n"+$Password | keepassxc-cli edit --password-prompt --username $username --notes $notes $DatabaseFilename "$Group/$title" 2>&1
	}
    return Test-Message($msg)
}
