<#
This function will synchronize or align information from PAM
with a KeePassXC database

#>

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
        Write-Host "KeePassXC files and group"
        Write-Host "DatabasePath '$DatabasePath'" -ForegroundColor Gray
        Write-Host "KeyFilePath '$KeyFilePath'" -ForegroundColor Gray
        Write-Host "Group '$Group'" -ForegroundColor Gray
    }

    if (-not $Script:kpInitialized) {
        $res= Initialize-KeePassXC -DatabasePath $DatabasePath -KeyFilePath $KeyFilePath -MasterPassword $MasterPassword -CreateDatabase:$CreateDatabase -Verbose:$Verbose -WhatIf:$WhatIf
    }

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
            if (-not $Quiet) {Write-Host "Duplicate '$key' with username '$($_.accountName)'"}
        }
        else 
        {
            $bgHash.Add($key, [PSCustomObject]@{server=$_.server; type=$_.accountType; username=$_.accountName; password=$_.accountPassword; verified=[bool]($_.verified)}) | Out-Null
        }
    }

    # 
    # Fetch entries for group from KeePassXC
    # Build hash table 
    #
    if (-not $Quiet) {Write-Host "Finding accounts from KeePassXC group '$Group'"}
    $entries= Get-KeePassXCEntry -Group $Group

    $kpHash= New-Object System.Collections.Hashtable
    $entries | %{
        $title= $_.title
        if (-not $Quiet) {Write-Host $title -ForegroundColor Gray}
        $kpHash.Add( $title, [PSCustomObject]@{username=$_.username; password=$_.password}) | Out-Null
    }
    if (-not $Quiet) {
        if ($entries.getType().Name -eq "PSCustomObject") {$cnt= 1} else {$cnt= $entries.count}
        Write-Host "Found '$cnt' accounts in KeePassXC" -ForegroundColor Gray
    }


    $diff= Compare-Object @($bghash.Keys) @($kphash.Keys) -IncludeEqual -CaseSensitive  | Sort-Object InputObject

    if (-not $Quiet) {Write-Host "Alining accounts from PAM with KeePassXC"}
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
            if (-not $Quiet) {Write-Host "Removing 'Recycle Bin'" -ForegroundColor Green}
            $res= Remove-KeePassXCGroup -Group "Recycle Bin"
        }
    } catch {}
}

# --- end-of-file ---