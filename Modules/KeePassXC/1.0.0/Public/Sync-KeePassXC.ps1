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

    if ($WhatIf) { $Quiet = $false }

    if ($pamAccounts -eq $null) { $pamAccounts = @() }
    if ($vaultAccounts -eq $null) { $vaultAccounts = @() }

    #
    # Build hash for vaultAccounts
    #
    $vaultHash = New-Object System.Collections.Hashtable
    $vaultAccounts | ForEach-Object {
        $vaultHash.Add($_.title, [PSCustomObject]@{ username = $_.username; password = $_.password; options = $_.options }) | Out-Null
    }

    #
    # Build hash table with key using server, type and username
    #
    $pamHash = New-Object System.Collections.Hashtable
    $pamAccounts | ForEach-Object {
        $key = "$($_.Server) # $($_.accountType) # $($_.accountName)"

        if ($pamHash.ContainsKey($key)) {
            if (-not $Quiet) { Write-Log "Duplicate '$key'" -Level Warning }
        }
        else {
            $pamHash.Add($key, [PSCustomObject]@{ server = $_.server; type = $_.accountType; username = $_.accountName; password = $_.accountPassword.Trim(); verified = [bool]($_.verified) }) | Out-Null
        }
    }

    if (-not $Quiet) {
        if ($Multiple) { Write-Log "Master database '$Script:kpDatabaseFilename'" -Level Debug }
        else { Write-Log "Database '$Script:kpDatabaseFilename'" -Level Debug }
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
                    Write-Log "WhatIf: Updating '$title'" -Level Info
                }
                else {
                    if (-not $Quiet) { Write-Log "Updating '$title'" -Level Info }

                    if ($Multiple) {
                        $fileMasterPassword = $vaultHash[$d.InputObject].options.password
                        $fileDatabaseFilename = Get-KeePassXCDatabaseFilename -Title $title -Multiple

                        if ($Update) {
                            Remove-Item -Path $fileDatabaseFilename -ErrorAction SilentlyContinue
                            $fileMasterPassword = New-BreakglassPassword -BlockLength 4
                            if (-not $Quiet) { Write-Log "Removed database '$fileDatabaseFilename'" -Level Debug }
                        }

                        if (Test-Path $fileDatabaseFilename) {
                            $res = Update-KeePassXCEntry -DatabaseFilename $fileDatabaseFilename -MasterPassword $fileMasterPassword -Group $Script:kpGroup -Title $title -Username $userName -Password $password -Verified:$verified
                            if (-not $Quiet) { Write-Log "Updated entry '$Script:kpGroup/$title' in database '$fileDatabaseFilename'" -Level Debug }
                        }
                        else {
                            $res = New-KeePassXCDatabase -DatabaseFilename $fileDatabaseFilename -KeyFileFilename $null -MasterPassword $fileMasterPassword
                            if (-not $Quiet) { Write-Log "Created database database '$fileDatabaseFilename'" -Level Debug }

                            $res = New-KeePassXCGroup -DatabaseFilename $fileDatabaseFilename -MasterPassword $fileMasterPassword -Group $Script:kpGroup
                            if (-not $Quiet) { Write-Log "Created group '$Script:kpGroup'" -Level Debug }

                            $res = New-KeePassXCEntry -DatabaseFilename $fileDatabaseFilename -MasterPassword $fileMasterPassword -Group $Script:kpGroup -Title $title -Username $userName -Password $password -Verified:$verified
                            if (-not $Quiet) { Write-Log "Added entry '$Script:kpGroup/$title'" -Level Debug }
                        }
                    }
                    else {
                        $res = Update-KeePassXCEntry -Group $Script:kpGroup -Title $title -Username $userName -Password $password -Verified:$verified
                        if (-not $Quiet) { Write-Log "Updated entry '$Script:kpGroup/$title'" -Level Debug }
                    }
                }
            }
            else {
                if (-not $Quiet) { Write-Log "No update '$($d.InputObject)'" -Level Debug }
            }
        }

        elseif ($d.SideIndicator -eq "<=") {
            #
            # Add new entry to KeePassXC
            #
            if ($WhatIf) {
                Write-Log "WhatIf: Adding '$title'" -Level Info
            }
            else {
                if (-not $Quiet) { Write-Log "Adding '$title'" -Level Info }

                if ($Multiple) {
                    $fileMasterPassword = New-BreakglassPassword -BlockLength 4
                    try {
                        $res = Update-KeePassXCEntry -Group $Script:kpFilePasswordGroup -Title $title -Username $userName -Password $fileMasterPassword
                        if (-not $Quiet) { Write-Log "Updated '$Script:kpFilePasswordGroup/$title'" -Level Debug }
                    }
                    catch {
                        if ($_.Exception.Message -eq "Not Found") {
                            $res = New-KeePassXCEntry -Group $Script:kpFilePasswordGroup -Title $title -Username $userName -Password $fileMasterPassword
                            if (-not $Quiet) { Write-Log "Added '$Script:kpFilePasswordGroup/$title'" -Level Debug }
                        }
                        else {
                            throw
                        }
                    }

                    $fileDatabaseFilename = Get-KeePassXCDatabaseFilename -Title $title -Multiple
                    if (Test-Path $fileDatabaseFilename) {
                        Remove-Item $fileDatabaseFilename
                        if (-not $Quiet) { Write-Log "Removed database '$fileDatabaseFilename'" -Level Debug }
                    }

                    $res = New-KeePassXCDatabase -DatabaseFilename $fileDatabaseFilename -KeyFileFilename $null -MasterPassword $fileMasterPassword
                    if (-not $Quiet) { Write-Log "Created database database '$fileDatabaseFilename'" -Level Debug }

                    $res = New-KeePassXCGroup -DatabaseFilename $fileDatabaseFilename -MasterPassword $fileMasterPassword -Group $Script:kpGroup
                    if (-not $Quiet) { Write-Log "Created group '$Script:kpGroup'" -Level Debug }

                    $res = New-KeePassXCEntry -DatabaseFilename $fileDatabaseFilename -MasterPassword $fileMasterPassword -Group $Script:kpGroup -Title $title -Username $userName -Password $password -Verified:$verified
                    if (-not $Quiet) { Write-Log "Added entry '$Script:kpGroup/$title'" -Level Debug }
                }
                else {
                    $res = New-KeePassXCEntry -Group $Script:kpGroup -Title $title -Username $userName -Password $password -Verified:$verified
                    if (-not $Quiet) { Write-Log "Added entry '$Script:kpGroup/$title'" -Level Debug }
                }
            }
        }

        else {
            #
            # Remove entry from KeePassXC
            #
            if ($WhatIf) {
                Write-Log "WhatIf: Removing '$title'" -Level Info
            }
            else {
                if (-not $Quiet) { Write-Log "Removing '$title'" -Level Info }

                if ($Multiple) {
                    $res = Remove-KeePassXCEntry -Group $Script:kpFilePasswordGroup -Title $title
                    if (-not $Quiet) { Write-Log "Removed entry '$Script:kpFilePasswordGroup/$title'" -Level Debug }

                    $fileDatabaseFilename = Get-KeePassXCDatabaseFilename -Title $title -Multiple
                    if (Test-Path $fileDatabaseFilename) {
                        Remove-Item $fileDatabaseFilename
                        if (-not $Quiet) { Write-Log "Removed database '$fileDatabaseFilename'" -Level Debug }
                    }
                }
                else {
                    $res = Remove-KeePassXCEntry -Group $Script:kpGroup -Title $title
                    if (-not $Quiet) { Write-Log "Removed entry '$Script:kpGroup/$title'" -Level Debug }
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