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
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [Object[]] $pamAccounts = @(),

        [Parameter(Mandatory = $false)]
        [Object[]] $vaultAccounts = @(),

        [Parameter(Mandatory = $false)]
        [switch] $Multiple = $false,

        [Parameter(Mandatory = $false)]
        [switch] $Update = $false,

        [Parameter(Mandatory = $false)]
        [switch] $Quiet = $false,

        [Parameter(Mandatory = $false)]
        [switch] $WhatIf = $false
    )

    if ($WhatIf) { $Quiet = $false }

    if ($pamAccounts -eq $null) { $pamAccounts = @() }
    if ($vaultAccounts -eq $null) { $vaultAccounts = @() }

    #
    # Build hash for vaultAccounts
    #
    $vaultHash = @{}
    $vaultAccounts | ForEach-Object {
        $vaultHash.Add($_.title, [PSCustomObject]@{username = $_.username; password = $_.password; options = $_.options}) | Out-Null
    }

    #
    # Build hash table with key using server, type and username
    #
    $pamHash = @{}
    $pamAccounts | ForEach-Object {
		
        $key = "$($_.Server) # $($_.accountType) # $($_.accountName)"

        if ($pamHash.ContainsKey($key)) {
            Write-Log -Message "Duplicate '$key'" -Level Warning -Quiet:$Quiet
        }
        else {
            $pamHash.Add($key, [PSCustomObject]@{server = $_.server; type = $_.accountType; username = $_.accountName; password = $_.accountPassword.Trim(); verified = [bool]($_.verified)}) | Out-Null
        }
    }

    if ($Multiple) { Write-Log -Message "Master database '$Script:kpDatabaseFilename'" -Level Info -Quiet:$Quiet }
    else { Write-Log -Message "Database '$Script:kpDatabaseFilename'" -Level Info -Quiet:$Quiet }

    $diff = Compare-Object @($pamHash.Keys) @($vaultHash.Keys) -IncludeEqual -CaseSensitive | Sort-Object InputObject
    foreach ($d in $diff) {

        $title = $d.InputObject
        $userName = $($pamHash[$d.InputObject].username)
        $password = $($pamHash[$d.InputObject].password)
        $verified = $($pamHash[$d.InputObject].verified)

        if ($d.SideIndicator -eq "==") {
            #
            # Same entry from BreakGlass list and KeePassXC list is found
            #
            if ($pamHash[$d.InputObject].password -ne $vaultHash[$d.InputObject].password) {
                #
                # Password has changed
                #
                if ($WhatIf) {
                    Write-Log -Message "WhatIf: Updating '$title'" -Level Success -Quiet:$Quiet
                }
                else {
                    Write-Log -Message "Updating '$title'" -Level Success -Quiet:$Quiet

                    if ($Multiple) {
                        $fileMasterPassword = $vaultHash[$d.InputObject].options.password
                        $fileDatabaseFilename = Get-KeePassXCDatabaseFilename -Title $title -Multiple

                        if ($Update) {
                            Remove-Item -Path $fileDatabaseFilename -ErrorAction SilentlyContinue
                            $fileMasterPassword = New-BreakglassPassword -BlockLength 4
                            Write-Log -Message "Removed database '$fileDatabaseFilename'" -Level Info -Quiet:$Quiet
                        }

                        if (Test-Path $fileDatabaseFilename) {
                            $res = Update-KeePassXCEntry -DatabaseFilename $fileDatabaseFilename -MasterPassword $fileMasterPassword -Group $Script:kpGroup -Title $title -Username $userName -Password $password -Verified:$verified -Quiet:$Quiet
                            Write-Log -Message "Updated entry '$Script:kpGroup/$title' in database '$fileDatabaseFilename'" -Level Info -Quiet:$Quiet
                        }
                        else {
                            $res = New-KeePassXCDatabase -DatabaseFilename $fileDatabaseFilename -KeyFileFilename $null -MasterPassword $fileMasterPassword -Quiet:$Quiet
                            Write-Log -Message "Created database '$fileDatabaseFilename'" -Level Info -Quiet:$Quiet

                            $res = New-KeePassXCGroup -DatabaseFilename $fileDatabaseFilename -MasterPassword $fileMasterPassword -Group $Script:kpGroup -Quiet:$Quiet
                            Write-Log -Message "Created group '$Script:kpGroup'" -Level Info -Quiet:$Quiet

                            $res = New-KeePassXCEntry -DatabaseFilename $fileDatabaseFilename -MasterPassword $fileMasterPassword -Group $Script:kpGroup -Title $title -Username $userName -Password $password -Verified:$verified -Quiet:$Quiet
                            Write-Log -Message "Added entry '$Script:kpGroup/$title'" -Level Info -Quiet:$Quiet
                        }
                    }
                    else {
                        $res = Update-KeePassXCEntry -Group $Script:kpGroup -Title $title -Username $userName -Password $password -Verified:$verified -Quiet:$Quiet
                        Write-Log -Message "Updated entry '$Script:kpGroup/$title'" -Level Info -Quiet:$Quiet
                    }
                }
            }
            else {
                Write-Log -Message "No update '$($d.InputObject)'" -Level Info -Quiet:$Quiet
            }
        }

        elseif ($d.SideIndicator -eq "<=") {
            #
            # Add new entry to KeePassXC
            #
            if ($WhatIf) {
                Write-Log -Message "WhatIf: Adding '$title'" -Level Success -Quiet:$Quiet
            }
            else {
                Write-Log -Message "Adding '$title'" -Level Success -Quiet:$Quiet

                if ($Multiple) {
                    $fileMasterPassword = $(New-BreakglassPassword -BlockLength 4)
                    try {
                        $res = Update-KeePassXCEntry -Group $Script:kpFilePasswordGroup -Title $title -Username $userName -Password $fileMasterPassword -Quiet:$Quiet
                        Write-Log -Message "Updated '$Script:kpFilePasswordGroup/$title'" -Level Info -Quiet:$Quiet
                    }
                    catch {
                        if ($_.Exception.Message -eq "Not Found") {
                            $res = New-KeePassXCEntry -Group $Script:kpFilePasswordGroup -Title $title -Username $userName -Password $fileMasterPassword -Quiet:$Quiet
                            Write-Log -Message "Added '$Script:kpFilePasswordGroup/$title'" -Level Info -Quiet:$Quiet
                        }
                        else {
                            throw
                        }
                    }

                    $fileDatabaseFilename = Get-KeePassXCDatabaseFilename -Title $title -Multiple
                    if (Test-Path $fileDatabaseFilename) {
                        Remove-Item $fileDatabaseFilename
                        Write-Log -Message "Removed database '$fileDatabaseFilename'" -Level Info -Quiet:$Quiet
                    }

                    $res = New-KeePassXCDatabase -DatabaseFilename $fileDatabaseFilename -KeyFileFilename $null -MasterPassword $fileMasterPassword -Quiet:$Quiet
                    Write-Log -Message "Created database '$fileDatabaseFilename'" -Level Info -Quiet:$Quiet

                    $res = New-KeePassXCGroup -DatabaseFilename $fileDatabaseFilename -MasterPassword $fileMasterPassword -Group $Script:kpGroup -Quiet:$Quiet
                    Write-Log -Message "Created group '$Script:kpGroup'" -Level Info -Quiet:$Quiet

                    $res = New-KeePassXCEntry -DatabaseFilename $fileDatabaseFilename -MasterPassword $fileMasterPassword -Group $Script:kpGroup -Title $title -Username $userName -Password $password -Verified:$verified -Quiet:$Quiet
                    Write-Log -Message "Added entry '$Script:kpGroup/$title'" -Level Info -Quiet:$Quiet
                }
                else {
                    $res = New-KeePassXCEntry -Group $Script:kpGroup -Title $title -Username $userName -Password $password -Verified:$verified -Quiet:$Quiet
                    Write-Log -Message "Added entry '$Script:kpGroup/$title'" -Level Info -Quiet:$Quiet
                }
            }
        }

        else {
            #
            # Remove entry from KeePassXC
            #
            if ($WhatIf) {
                Write-Log -Message "WhatIf: Removing '$title'" -Level Success -Quiet:$Quiet
            }
            else {
                Write-Log -Message "Removing '$title'" -Level Success -Quiet:$Quiet

                if ($Multiple) {
                    $res = Remove-KeePassXCEntry -Group $Script:kpFilePasswordGroup -Title $title -Quiet:$Quiet
                    Write-Log -Message "Removed entry '$Script:kpFilePasswordGroup/$title'" -Level Info -Quiet:$Quiet

                    $fileDatabaseFilename = Get-KeePassXCDatabaseFilename -Title $title -Multiple
                    if (Test-Path $fileDatabaseFilename) {
                        Remove-Item $fileDatabaseFilename
                        Write-Log -Message "Removed database '$fileDatabaseFilename'" -Level Info -Quiet:$Quiet
                    }
                }
                else {
                    $res = Remove-KeePassXCEntry -Group $Script:kpGroup -Title $title -Quiet:$Quiet
                    Write-Log -Message "Removed entry '$Script:kpGroup/$title'" -Level Info -Quiet:$Quiet
                }
            }
        }
    }

    # 
    # remove "Recycle Bin"
    #
    try {
        if ($WhatIf) {
            Write-Log -Message "WhatIf: Removing 'Recycle Bin'" -Level Success -Quiet:$Quiet
        }
        else {
            Write-Log -Message "Removing 'Recycle Bin'" -Level Info -Quiet:$Quiet
            $res = Remove-KeePassXCGroup -Group "Recycle Bin" -Quiet:$Quiet
        }
    } catch {}
}

# --- end-of-file ---
