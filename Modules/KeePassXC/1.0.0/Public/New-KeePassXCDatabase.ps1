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
function New-KeePassXCDatabase {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string] $DatabaseFilename,

        [Parameter(Mandatory = $false)]
        [string] $KeyFileFilename,

        [Parameter(Mandatory = $true)]
        [SecureString] $MasterPassword,

        [Parameter(Mandatory = $false)]
        [switch] $Quiet = $false,

        [Parameter(Mandatory = $false)]
        [switch] $WhatIf = $false
    )

    if ($WhatIf) { $Quiet = $false }

    Write-Log -Message "Creating KeePassXC database '$DatabaseFilename'" -Level Info -Quiet:$Quiet

    $ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($MasterPassword)
    $plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)
    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)

    # CLI requires password to be entered twice for confirmation during creation
    $passwordConfirm = $plainPassword + "`n" + $plainPassword

    if ($KeyFileFilename) {
        $msg = $passwordConfirm | keepassxc-cli db-create --key-file $KeyFileFilename $DatabaseFilename 2>&1
    }
    else {
        $msg = $passwordConfirm | keepassxc-cli db-create $DatabaseFilename 2>&1
    }

    return Test-Message($msg)
}

# --- end-of-file ---
