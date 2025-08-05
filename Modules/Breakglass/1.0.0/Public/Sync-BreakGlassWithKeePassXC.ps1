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
function Sync-BreakglassWithKeePassXC {
    param (
        [Parameter(Mandatory=$false)][string] $Group= $Script:kpGroup,

        [Parameter(Mandatory=$false)][Object[]] $pamAccounts = @(),
        [Parameter(Mandatory=$false)][Object[]] $vaultAccounts = @(),

        [Parameter(Mandatory=$false)][switch] $Quiet= $false,
        [Parameter(Mandatory=$false)][switch] $WhatIf= $false
    )

    if ($WhatIf) {$quiet= $false}

    if ($pamAccounts -eq $null) {$pamAccounts= @()}
    if ($vaultAccounts -eq $null) {$vaultAccounts= @()}

    #
    # Build hash for vaultAccounts
    #
    $vaultHash= New-Object System.Collections.Hashtable
    $vaultAccounts | %{
        $vaultHash.Add( $_.title, [PSCustomObject]@{username=$_.username; password=$_.password.Trim()}) | Out-Null
    }

    #
    # Build hash table with key using server, type and username
    #
    $pamHash= New-Object System.Collections.Hashtable
    $pamAccounts | %{
		
        $key= $($_.Server)+" | "+$($_.accountType)+" | "+$($_.accountName)

        if ($pamHash.ContainsKey($key)) {
            if (-not $Quiet) {Write-Host "Duplicate '$key'" -ForegroundColor Yellow}
        }
        else 
        {
            $pamHash.Add($key, [PSCustomObject]@{server=$_.server; type=$_.accountType; username=$_.accountName; password=$_.accountPassword.Trim(); verified=[bool]($_.verified)}) | Out-Null
        }
    }


    $diff= Compare-Object @($pamHash.Keys) @($vaultHash.Keys) -IncludeEqual -CaseSensitive  | Sort-Object InputObject
    foreach ($d in $diff) {

        $title= $d.InputObject
		$userName= $($pamHash[$d.InputObject].username)
		$password= $($pamHash[$d.InputObject].password)
        $verified= $($pamHash[$d.InputObject].verified)

        if ($d.SideIndicator -eq "==") {
            #
            # Same entry from BreakGlass list and KeePassXC list is found
            #
            if ($pamHash[$d.InputObject].password -ne $vaultHash[$d.InputObject].password) {
                #
                # Password has changed
                #
				if ($WhatIf) {
					Write-Host "WhatIf: Updating '$Title'" -ForegroundColor Green
				}
				else {
					if (-not $Quiet) {Write-Host "Updating '$title'" -ForegroundColor Green}
					$res= Update-KeePassXCEntry -Group $Group -Title $title -Username $userName -Password $password -Verified:$verified
				}
            }
            else {
                if (-not $Quiet) {Write-Host "No update '$($d.InputObject)'" -ForegroundColor Gray}
            }
        }

        elseif ($d.SideIndicator -eq "<=") {
            #
            # Add new entry to KeePassXC
            #
            if ($WhatIf) {
                Write-Host "WhatIf: Adding '$Title'" -ForegroundColor Green
            }
            else {
                if (-not $Quiet) {Write-Host "Adding '$title'" -ForegroundColor Green}
                $res= New-KeePassXCEntry -Group $Group -Title $Title -Username $userName -Password $password -Verified:$Verified
            }
        }

        else {
            #
            # Remove entry from KeePassXC
            #
            if ($WhatIf) {
                Write-Host "WhatIf: Removing '$Title'" -ForegroundColor Green
            }
            else {
                if (-not $Quiet) {Write-Host "Removing '$title'" -ForegroundColor Green}
                $res= Remove-KeePassXCEntry -Group $Group -Title $title
            }
        }
    }

<#
    # 
    # remove "Recycle Bin"
    #
    try {
        if ($WhatIf) {
            Write-Host "WhatIf: Removing 'Recycle Bin'" -ForegroundColor Green
        }
        else {
            if (-not $Quiet) {Write-Host "Removing 'Recycle Bin'" -ForegroundColor Gray}
            $res= Remove-KeePassXCGroup -Group "Recycle Bin"
        }
    } catch {}
#>
}

# --- end-of-file ---