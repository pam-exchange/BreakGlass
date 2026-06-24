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
# ------------------------------------------------------------------------------------
function Get-BreakglassFromPasswordSafe {
    param (
        [Parameter(Mandatory=$false)][switch] $Quiet= $false,
        [Parameter(Mandatory=$false)][switch] $WhatIf= $false
    )

    if ($WhatIf) {$quiet= $false}

    $list= New-Object System.Collections.ArrayList

    #
    # Get all breakglass accounts
    # PAM smartrule will filter accounts for breakglass
    #
    $accounts= Get-PwsManagedAccount

    #
    # loop through all accounts (API enabled) and fetch password for each.
    # it is required to have a request for fetching a password
    #
    foreach ($acc in $accounts) {
        if ($acc.ApiEnabled -eq $false) {
			Write-Host "$($acc.SystemName) | $($acc.PlatformName) | $($acc.AccountName) -- ignored (not API enabled)" -ForegroundColor Yellow
            continue
        }

        $reqID= New-PwsRequest -AccountID $acc.AccountID -SystemID $acc.SystemID -Duration 5 -Conflict Reuse
        $pwd= Get-PwsManagedAccountPassword -RequestID $reqID -useDSS:$acc.useDSS

        $list.add( [PSCustomObject]@{
						server=$($acc.SystemName); 
						accountType=$($acc.PlatformName); 
						accountID=$($acc.AccountID); 
						accountName=$($acc.AccountName); 
						accountPassword=$pwd; 
						verified=$Verified; 
						useDSS=$($acc.useDSS)} 
				) | Out-Null
    }

    return $list
}

# --- end-of-file ---