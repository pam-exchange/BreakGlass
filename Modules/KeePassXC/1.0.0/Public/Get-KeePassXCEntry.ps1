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
function Get-KeePassXCEntry {
    param (
        [Parameter(Mandatory=$false)][string]$DatabasePath= $Script:kpDatabasePath,
        [Parameter(Mandatory=$false)][string]$KeyFilePath= $Script:kpKeyFilePath,
        [Parameter(Mandatory=$false)][string]$MasterPassword= $Script:kpMasterPassword,
        [Parameter(Mandatory=$false)][string]$Group= $Script:kpGroup,
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
			$e= $MasterPassword | keepassxc-cli show --attributes Title --attributes UserName --attributes Password --attributes Notes --key-file $KeyFilePath $DatabasePath "$Group/$Title" 2>&1
		} else {
			$e= $MasterPassword | keepassxc-cli show --attributes Title --attributes UserName --attributes Password --attributes Notes $DatabasePath "$Group/$Title" 2>&1
		}

        if ($e.length -lt 4) {
            # Array with length 4 is expected
            Test-Message($e)
        }

        if ($e[4] -match "-----") {
            $password= ($e[4..($e.length-1)] -join "`n").Trim()
        } 
        else {
            $password= $e[3]
        }

        return [PSCustomObject]@{title=$e[1]; username=$e[2]; password=$password}
    }

    #
    # Fetch all entries in Group
    #
    $entries= New-Object System.Collections.ArrayList

    # 
    # If the group is empty the list returned is everything from KeePassXC
    # this includes groups, entries from groups, and empth
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
			$e= $MasterPassword | keepassxc-cli show --attributes Title --attributes UserName --attributes Password --attributes Notes --key-file $KeyFilePath $DatabasePath "$Group/$t" 2>&1
		} else {
			$e= $MasterPassword | keepassxc-cli show --attributes Title --attributes UserName --attributes Password --attributes Notes $DatabasePath "$Group/$t" 2>&1
		}

        if ($e.length -lt 4) {
            # Array with length 4 is expected
            Test-Message($e)
        }

        if ($e[4] -match "-----") {
            $password= ($e[4..($e.length-1)] -join "`n").Trim()
        } 
        else {
            $password= $e[3]
        }

        $entries.Add([PSCustomObject]@{title=$e[1]; username=$e[2]; password=$password}) | Out-Null
    }

    return $entries
}
