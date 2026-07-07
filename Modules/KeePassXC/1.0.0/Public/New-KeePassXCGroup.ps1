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
function New-KeePassXCGroup {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string] $DatabaseFilename = $Script:kpDatabaseFilename,

        [Parameter(Mandatory = $false)]
        [string] $KeyFileFilename = $Script:kpKeyFileFilename,

        [Parameter(Mandatory = $false)]
        [SecureString] $MasterPassword = $Script:kpMasterPassword,

        [Parameter(Mandatory = $true)]
        [string] $Group,

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
    $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)

    if ($KeyFileFilename) {
        $msg = $plainPassword | keepassxc-cli group-add --key-file $KeyFileFilename $DatabaseFilename $Group 2>&1
    }
    else {
        $msg = $plainPassword | keepassxc-cli group-add $DatabaseFilename $Group 2>&1
    }

    return Test-Message($msg)
}

# --- end-of-file ---
