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
function Sync-BreakglassToKeePassXC {
    param (
        [Parameter(Mandatory=$false)][string] $DatabasePath= $Script:kpDatabasePath,
        [Parameter(Mandatory=$false)][string] $KeyFilePath= $Script:kpKeyFilePath,
        [Parameter(Mandatory=$false)][string] $MasterPassword= $Script:kpMasterPassword,
        [Parameter(Mandatory=$false)][string] $Group= $Script:kpGroup,
        [Parameter(Mandatory=$false)][switch] $CreateDatabase= $false,

        [Parameter(Mandatory=$true)][Object[]] $Accounts,

        [Parameter(Mandatory=$false)][switch] $Quiet= $false,
        [Parameter(Mandatory=$false)][switch] $WhatIf= $false
    )

    if ($WhatIf) {$quiet= $false}

    if (-not $Quiet) {
        Write-Host "KeePassXC files and group"  -ForegroundColor White
        Write-Host "DatabasePath '$DatabasePath'" -ForegroundColor Gray
        Write-Host "KeyFilePath '$KeyFilePath'" -ForegroundColor Gray
        Write-Host "Group '$Group'" -ForegroundColor Gray
    }

    if (-not $Script:kpInitialized) {
        $res= Initialize-KeePassXC -DatabasePath $DatabasePath -KeyFilePath $KeyFilePath -MasterPassword $MasterPassword -CreateDatabase:$CreateDatabase -Quiet:$Quiet -WhatIf:$WhatIf
    }

    # 
    # If a valid entry is found in "Recycle Bin" it is seen as 
    # already available in KeePassXC.
    # Just remove "Recycle Bin"
    #
    if (Test-KeePassXCGroup -Group "Recycle Bin"){
        if ($WhatIf) {
            Write-Host "Removing 'Recycle Bin'" -ForegroundColor Green
        }
        else {
            if (-not $Quiet) {Write-Host "Removing 'Recycle Bin'" -ForegroundColor Gray}
            $res= Remove-KeePassXCGroup -Group "/Recycle Bin"
        }
    }

    #
    # Now proceed without "Recycle Bin" being around
    #
    if ($Group) {
        $Group= $Group.Trim(" /")

        if (-not $(Test-KeePassXCGroup -Group $Group)){
            if ($WhatIf) {
                Write-Host "Adding group '$Group'" -ForegroundColor Green
            }
            else {
                if (-not $Quiet) {Write-Host "Adding group '$Group'" -ForegroundColor Gray}
                $res= New-KeePassXCGroup -Group $Group
            }
        }
    }

    #
    # Build hash table with key using server, type and username
    #
    $bgHash= New-Object System.Collections.Hashtable
    $Accounts | %{
		
        $key= $($_.Server)+" | "+$($_.accountType)
        $key+= " | "+$($_.accountName)

        if ($bgHash.ContainsKey($key)) {
            if (-not $Quiet) {Write-Host "Duplicate '$key' with username '$($_.accountName)'" -ForegroundColor Gray}
        }
        else 
        {
            $bgHash.Add($key, [PSCustomObject]@{server=$_.server; type=$_.accountType; username=$_.accountName; password=$_.accountPassword.Trim(); verified=[bool]($_.verified)}) | Out-Null
        }
    }

    # 
    # Fetch entries for group from KeePassXC
    # Build hash table 
    #
    if (-not $Quiet) {Write-Host "Finding accounts from KeePassXC group '$Group'" -ForegroundColor White}
    $entries= Get-KeePassXCEntry -Group $Group

    $kpHash= New-Object System.Collections.Hashtable
    $entries | %{
        $title= $_.title
        if (-not $Quiet) {Write-Host $title -ForegroundColor Gray}
        $kpHash.Add( $title, [PSCustomObject]@{username=$_.username; password=$_.password.Trim()}) | Out-Null
    }
    if (-not $Quiet) {
        if ($null -eq $entries) {$cnt= 0}
        elseif ($entries.getType().Name -eq "PSCustomObject") {$cnt= 1} else {$cnt= $entries.count}
        Write-Host "Found '$cnt' accounts in KeePassXC" -ForegroundColor Gray
    }


    $diff= Compare-Object @($bghash.Keys) @($kphash.Keys) -IncludeEqual -CaseSensitive  | Sort-Object InputObject

    if (-not $Quiet) {Write-Host "Aligning accounts from PAM with KeePassXC" -ForegroundColor White}
    foreach ($d in $diff) {

        #Write-Host $d

        if ($d.SideIndicator -eq "==") {
            #
            # Same entry from BreakGlass list and KeePassXC list is found
            #
            if ($bgHash[$d.InputObject].password -ne $kpHash[$d.InputObject].password) {
                # Password has changed

                $title= $d.InputObject
			    $userName= $($bgHash[$d.InputObject].username)
                $password= $($bgHash[$d.InputObject].password)
                $verified= $($bgHash[$d.InputObject].verified)

				if ($WhatIf) {
					Write-Host "WhatIf: Updating '$Title'" -ForegroundColor Green
				}
				else {
					if (-not $Quiet) {Write-Host "Updating '$title'" -ForegroundColor Green}
					$res= Update-KeePassXCEntry -Group $Group -Title $Title -Username $userName -Password $password -Verified:$verified
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
            $title= $d.InputObject
			$userName= $($bgHash[$d.InputObject].username)
			$password= $($bgHash[$d.InputObject].password)
            $verified= $($bgHash[$d.InputObject].verified)

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
            $title= $d.InputObject
			
            if ($WhatIf) {
                Write-Host "WhatIf: Removing '$Title'" -ForegroundColor Green
            }
            else {
                if (-not $Quiet) {Write-Host "Removing '$title'" -ForegroundColor Green}
                $res= Remove-KeePassXCEntry -Group $Group -Title $title
            }
        }
    }

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
}

# --- end-of-file ---