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

    $requests= Get-PwsRequest -Refresh

    #
    # loop through all accounts and fetch password for each.
    # it is required to have a request for fetching a password
    #
    foreach ($acc in $Accounts) {

        #
        # Update password and fetch the new password
        #
        try {
            if ($WhatIf) {Write-Host "WhatIf: " -ForegroundColor Green -NoNewline}
            if (-not $Quiet) {Write-Host "$($acc.Server) | $($acc.accountType) | $($acc.accountName) -- " -NoNewline -ForegroundColor Gray }

            if (-not $WhatIf) {
                $res= Update-PwsManagedAccountPassword -AccountID $acc.AccountID -Password $Password
            }

            if (-not $Quiet) {Write-Host "Password updated" -ForegroundColor Green}
        }
        catch {
            if (-not $Quiet) {Write-Host "Password not updated" -ForegroundColor Yellow}
            continue
        }
        if ($WhatIf) {
            # No need to fetch the new password
            continue
        }

        $cnt= 0
        do {
            #
            # Loop is required for the scenario that a request expired since it was requested
            # and tested when filtering by IDs and datetime.
            #
            # A rare scenario, but it may happen that the test was done (not expired) and it then
            # expires before the password is fetched using the now expired RequestID. 
            # If there is a time mismatch between calling system and PAM, the opposite scenario
            # that a new request is requested although a valid request still exist.
            # If so, an exception is thrown by the calling function. 
            # Wait a bit and try again. If the issue is different, do this at most 5 times,
            # then rethrow the exception.
            #

            try {
                # Find request by IDs and filter request already expired
                $now= Get-Date
                $req= $requests | Where-Object {($_.accountID -eq $acc.AccountID) -and ($now -lt [DateTime]$($_.ExpiresDate))}

                if (-not $req) {
                    $reqID= New-PwsRequest -AccountID $acc.ID -SystemID $acc.SystemId -Duration 15
                } else {
                    $reqID= $req.RequestID
                }

                $pwd= Get-PwsManagedAccountPassword -RequestID $reqID -useDSS:$($acc.useDSS)
                $acc.accountPassword= $pwd
                break
            } 
            catch {
                $cnt++
                if (-not $Quiet) {Write-Host "$($_.Exception.Message) - $($_.Exception.Details)" -ForegroundColor DarkGray}
                if ($cnt -gt 5) {
                    throw
                }
                Sleep -Milliseconds 500
            }
        } while ($true)
    }
}

# --- end-of-file ---