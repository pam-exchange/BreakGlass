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
function Sync-KeePassXC {
    param (
        [Parameter(Mandatory=$false)][Object[]] $pamAccounts = @(),
        [Parameter(Mandatory=$false)][Object[]] $vaultAccounts = @(),

        [Parameter(Mandatory=$false)][switch] $Multiple= $false,
        [Parameter(Mandatory=$false)][switch] $Update= $false,
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
        #$vaultHash.Add( $_.title, [PSCustomObject]@{username=$_.username; password=$_.password.Trim();options= $_.options}) | Out-Null
        $vaultHash.Add( $_.title, [PSCustomObject]@{username=$_.username; password=$_.password;options= $_.options}) | Out-Null
    }

    #
    # Build hash table with key using server, type and username
    #
    $pamHash= New-Object System.Collections.Hashtable
    $pamAccounts | %{
		
        $key= $($_.Server)+" # "+$($_.accountType)+" # "+$($_.accountName)

        if ($pamHash.ContainsKey($key)) {
            if (-not $Quiet) {Write-Host "Duplicate '$key'" -ForegroundColor Yellow}
        }
        else 
        {
            $pamHash.Add($key, [PSCustomObject]@{server=$_.server; type=$_.accountType; username=$_.accountName; password=$_.accountPassword.Trim(); verified=[bool]($_.verified)}) | Out-Null
        }
    }

	if (-not $Quiet) {
		if ($Multiple) { Write-Host "Master database '$script:kpDatabaseFilename'" -ForegroundColor Gray }
		else           { Write-Host "Database '$script:kpDatabaseFilename'" -ForegroundColor Gray }
	}

    $diff= Compare-Object @($pamHash.Keys) @($vaultHash.Keys) -IncludeEqual -CaseSensitive | Sort-Object InputObject
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
                    if (-not $Quiet) {Write-Host "Updating '$Title'" -ForegroundColor Green}

                    if ($Multiple) {
                        $fileMasterPassword= $vaultHash[$d.InputObject].options.password
                        $fileDatabaseFilename= Get-KeePassXCDatabaseFilename -Title $Title -Multiple

                        if ($Update) {
                            Remove-Item -Path $fileDatabaseFilename -ErrorAction SilentlyContinue
                            $fileMasterPassword= New-BreakglassPassword -BlockLength 4
                            if (-not $Quiet) {Write-Host "Removed database '$fileDatabaseFilename'" -ForegroundColor Gray}
                        }

                        if (Test-Path $fileDatabaseFilename) {
                            $res= Update-KeePassXCEntry -DatabaseFilename $fileDatabaseFilename -MasterPassword $fileMasterPassword -Group $Script:kpGroup -Title $title -Username $userName -Password $password -Verified:$verified
							if (-not $Quiet) {Write-Host "Updated entry '$script:kpGroup/$title' in database '$fileDatabaseFilename'" -ForegroundColor Gray}
                        } 
                        else {
							#if (-not $Quiet) {Write-Host "Adding '$title' to database '$fileDatabaseFilename'" -ForegroundColor Gray}
							
                            $res= New-KeePassXCDatabase -DatabaseFilename $fileDatabaseFilename -KeyFileFilename $null -MasterPassword $fileMasterPassword
							if (-not $Quiet) {Write-Host "Created database database '$fileDatabaseFilename'" -ForegroundColor Gray}
                            
                            $res= New-KeePassXCGroup -DatabaseFilename $fileDatabaseFilename -MasterPassword $fileMasterPassword -Group $Script:kpGroup 
							if (-not $Quiet) {Write-Host "Created group '$script:kpGroup'" -ForegroundColor Gray}
							
                            $res= New-KeePassXCEntry -DatabaseFilename $fileDatabaseFilename -MasterPassword $fileMasterPassword -Group $Script:kpGroup -Title $Title -Username $userName -Password $password -Verified:$verified
							if (-not $Quiet) {Write-Host "Added entry '$script:kpGroup/$Title'" -ForegroundColor Gray}
                        }
                    }
                    else {
					    $res= Update-KeePassXCEntry -Group $Script:kpGroup -Title $title -Username $userName -Password $password -Verified:$verified
                        if (-not $Quiet) {Write-Host "Updated entry '$Script:kpGroup/$title'" -ForegroundColor Gray}
                    }
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

                if ($Multiple) {
                    $fileMasterPassword= $(New-Breakglasspassword -BlockLength 4)
                    try {
                        $res= Update-KeePassXCEntry -Group $Script:kpFilePasswordGroup -Title $Title -Username $userName -Password $fileMasterPassword
                        if (-not $Quiet) {Write-Host "Updated '$Script:kpFilePasswordGroup/$title'" -ForegroundColor Gray}
                    }
                    catch {
                        if ($_.Exception.Message -eq "Not Found") {
                            $res= New-KeePassXCEntry -Group $Script:kpFilePasswordGroup -Title $Title -Username $userName -Password $fileMasterPassword
                            if (-not $Quiet) {Write-Host "Added '$Script:kpFilePasswordGroup/$title'" -ForegroundColor Gray}
                        }
                        else {
                            throw
                        }
                    }

                    $fileDatabaseFilename= Get-KeePassXCDatabaseFilename -Title $Title -Multiple
                    if (Test-Path $fileDatabaseFilename) {
                        Remove-Item $fileDatabaseFilename
                        if (-not $Quiet) {Write-Host "Removed database '$fileDatabaseFilename'" -ForegroundColor Gray}
                    }
					#if (-not $Quiet) {Write-Host "Adding '$Title' to database '$fileDatabaseFilename'" -ForegroundColor Gray}
                    
					$res= New-KeePassXCDatabase -DatabaseFilename $fileDatabaseFilename -KeyFileFilename $null -MasterPassword $fileMasterPassword
					if (-not $Quiet) {Write-Host "Created database database '$fileDatabaseFilename'" -ForegroundColor Gray}
					
                    $res= New-KeePassXCGroup -DatabaseFilename $fileDatabaseFilename -MasterPassword $fileMasterPassword -Group $Script:kpGroup 
					if (-not $Quiet) {Write-Host "Created group '$script:kpGroup'" -ForegroundColor Gray}
					
                    $res= New-KeePassXCEntry -DatabaseFilename $fileDatabaseFilename -MasterPassword $fileMasterPassword -Group $Script:kpGroup -Title $Title -Username $userName -Password $password -Verified:$verified
					if (-not $Quiet) {Write-Host "Added entry '$script:kpGroup/$Title'" -ForegroundColor Gray}
                }
                else {
                    $res= New-KeePassXCEntry -Group $Script:kpGroup -Title $Title -Username $userName -Password $password -Verified:$Verified
                    if (-not $Quiet) {Write-Host "Added entry '$Script:kpGroup/$title'" -ForegroundColor Gray}
                }
            }
        }

        else {
			#if (-not $Quiet) {Write-Host "Remove KeePassXC '$title'" -ForegroundColor Gray}
            #
            # Remove entry from KeePassXC
            #
            if ($WhatIf) {
                Write-Host "WhatIf: Removing '$Title'" -ForegroundColor Green
            }
            else {
                if (-not $Quiet) {Write-Host "Removing '$title'" -ForegroundColor Green}
                
                if ($Multiple) {
                    $res= Remove-KeePassXCEntry -Group $Script:kpFilePasswordGroup -Title $title
                    if (-not $Quiet) {Write-Host "Removed entry '$Script:kpFilePasswordGroup/$title'" -ForegroundColor Gray}

                    $fileDatabaseFilename= Get-KeePassXCDatabaseFilename -Title $Title -Multiple
                    if (Test-Path $fileDatabaseFilename) {
                        Remove-Item $fileDatabaseFilename
                        if (-not $Quiet) {Write-Host "Removed database '$fileDatabaseFilename'" -ForegroundColor Gray}
                    }
                }
                else {
                    $res= Remove-KeePassXCEntry -Group $Script:kpGroup -Title $title
                    if (-not $Quiet) {Write-Host "Removed entry '$Script:kpGroup/$title'" -ForegroundColor Gray}
                }
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