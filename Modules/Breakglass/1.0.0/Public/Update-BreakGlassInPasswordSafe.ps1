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
function Update-BreakglassInPasswordSafe {
    param (
        [Parameter(Mandatory=$true)][Object[]] $Accounts,
        [Parameter(Mandatory=$false)][string] $Password,

        [Parameter(Mandatory=$false)][switch] $Quiet= $false,
        [Parameter(Mandatory=$false)][switch] $WhatIf= $false
    )

    if ($WhatIf) {$quiet= $false}

    #
    # loop through all accounts and fetch password for each.
    # it is required to have a request for fetching a password
    #
    foreach ($acc in $Accounts) {

        #
        # Update password and fetch the new password
        #
        try {
            if ($WhatIf) {Write-Log "WhatIf: " -Level Info -NoNewline}
            #if (-not $Quiet) {Write-Host "$($acc.Server) | $($acc.accountType) | $($acc.accountName) -- " -NoNewline -ForegroundColor Gray }
			if (-not $Quiet) {Write-Log "$($acc.Server) | $($acc.accountType) | $($acc.accountName) -- " -Level Debug -NoNewline }

            if (-not $WhatIf) {
                $res = Update-PwsManagedAccountPassword -AccountID $acc.AccountID -Password $Password
            }

            #if (-not $Quiet) {Write-Host "Password updated" -ForegroundColor Green}
			if (-not $Quiet) { Write-Log "Password updated" -Level Debug -ForegroundColor Green }
        }
        catch {
            #if (-not $Quiet) {Write-Host "Password not updated" -ForegroundColor Yellow}
			if (-not $Quiet) { Write-Log "Password not updated" -Level Warning }
            continue
        }
        if ($WhatIf) {
            # No need to fetch the new password
            continue
        }

        $reqID = New-PwsRequest -AccountID $acc.accountID -SystemName $acc.server -Duration 15

        $pwd = Get-PwsManagedAccountPassword -RequestID $reqID -useDSS:$($acc.useDSS)
        $acc.accountPassword= $pwd

        #
        # To-Do: How to verify password?
        #
        #$acc.verified= Test-PwsManagedAccountPassword -AccountID $acc.AccountID

    }
}

# --- end-of-file ---