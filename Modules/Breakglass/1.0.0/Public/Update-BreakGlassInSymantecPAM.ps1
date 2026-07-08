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


function Update-BreakglassInSymantecPAM {
    param (
        [Parameter(Mandatory=$true)][Object[]] $Accounts,
        [Parameter(Mandatory=$false)][string] $Password,

        [Parameter(Mandatory=$false)][switch] $Quiet= $false,
        [Parameter(Mandatory=$false)][switch] $WhatIf= $false
    )

    if ($WhatIf) {$quiet= $false}

    foreach ($acc in $Accounts) {
        try {
            #if ($WhatIf) {Write-Host "WhatIf: " -ForegroundColor Green -NoNewline}
            if ($WhatIf) {Write-Host "WhatIf: " -Level Info -NoNewline}
            #if (-not $Quiet) {Write-Host "$($acc.Server) | $($acc.accountType) | $($acc.accountName) -- " -NoNewline -ForegroundColor Gray }
            if (-not $Quiet) {Write-Log "$($acc.Server) | $($acc.accountType) | $($acc.accountName) -- " -Level Debug -NoNewline }

            if (-not $WhatIf) {
                $res= Update-SymTargetAccountPassword -AccountID $acc.accountID -Password $Password
            }
        } 
        catch {
            #if (-not $Quiet) {Write-Host "Password not updated" -ForegroundColor Yellow}
            if (-not $Quiet) { Write-Log "Password not updated" -Level Warning }
            continue
        }

        #if (-not $Quiet) {Write-Host "Password updated" -ForegroundColor Green}
		if (-not $Quiet) { Write-Log "Password updated" -Level Info }

        $pwd= Get-SymTargetAccountPassword -AccountID $acc.accountID
        $acc.accountpassword= $pwd
    }
}

# --- end-of-file ---