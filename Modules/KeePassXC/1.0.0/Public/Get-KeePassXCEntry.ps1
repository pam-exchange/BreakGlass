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
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string] $DatabaseFilename = $Script:kpDatabaseFilename,

        [Parameter(Mandatory = $false)]
        [string] $KeyFileFilename = $Script:kpKeyFileFilename,

        [Parameter(Mandatory = $false)]
        [SecureString] $MasterPassword = $Script:kpMasterPassword,

        [Parameter(Mandatory = $false)]
        [string] $Group = $Script:kpGroup,

        [Parameter(Mandatory = $false)]
        [string] $Title,
		
        [Parameter(Mandatory = $false)]
        [switch] $Quiet = $false,

        [Parameter(Mandatory = $false)]
        [switch] $WhatIf = $false
    )

    if (-not $Script:kpInitialized) {
        $msg = "KeePassXC module is not initialized"
        Write-Log -Message $msg -Level Warning -Quiet:$Quiet
        throw (New-Object KeePassXCException($EXCEPTION_INITIALIZE, $msg))
    }

    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($MasterPassword)
    $plainMasterPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)

    if ($Title) {
        #
        # Fetch one entry
        #
        if ($KeyFileFilename) {
            $e = $plainMasterPassword | keepassxc-cli show --attributes Title --attributes UserName --attributes Password --attributes Notes --key-file $KeyFileFilename $DatabaseFilename "$Group/$Title" 2>&1
        }
        else {
            $e = $plainMasterPassword | keepassxc-cli show --attributes Title --attributes UserName --attributes Password --attributes Notes $DatabaseFilename "$Group/$Title" 2>&1
        }

        if ($e.Length -lt 4) {
            # Array with length 4 is expected
            return Test-Message($e)
        }

        if ($e[4] -match "-----") {
            $password = ($e[4..($e.Length - 1)] -join "`n").Trim()
        } 
        else {
            $password = $e[3]
        }

        return [PSCustomObject]@{ title = $e[1]; username = $e[2]; password = $password }
    }

    #
    # Fetch all entries in Group
    #
    $entries = New-Object System.Collections.ArrayList

    # 
    # If the group is empty the list returned is everything from KeePassXC
    # this includes groups, entries from groups, and empth
    # ignore all except entries from root level
    #
    if ($KeyFileFilename) {
        $list = $plainMasterPassword | keepassxc-cli ls --key-file $KeyFileFilename $DatabaseFilename $Group 2> $null | Where-Object { $_ -notmatch "\[empty\]|.*/$|^ " }
    }
    else {
        $list = $plainMasterPassword | keepassxc-cli ls $DatabaseFilename $Group 2> $null | Where-Object { $_ -notmatch "\[empty\]|.*/$|^ " }
    }

    # TO-DO: Error handling, invalid parameters

    foreach ($t in $list) {
        if ($KeyFileFilename) {
            $e = $plainMasterPassword | keepassxc-cli show --attributes Title --attributes UserName --attributes Password --attributes Notes --key-file $KeyFileFilename $DatabaseFilename "$Group/$t" 2>&1
        }
        else {
            $e = $plainMasterPassword | keepassxc-cli show --attributes Title --attributes UserName --attributes Password --attributes Notes $DatabaseFilename "$Group/$t" 2>&1
        }

        if ($e.Length -lt 4) {
            # Array with length 4 is expected
            Test-Message($e)
            continue
        }

        if ($e[4] -match "-----") {
            $password = ($e[4..($e.Length - 1)] -join "`n").Trim()
        } 
        else {
            $password = $e[3]
        }

        $entries.Add([PSCustomObject]@{ title = $e[1]; username = $e[2]; password = $password }) | Out-Null
    }

    return $entries
}

# --- end-of-file ---
