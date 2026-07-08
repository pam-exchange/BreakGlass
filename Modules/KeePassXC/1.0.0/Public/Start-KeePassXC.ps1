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
function Start-KeePassXC {
    param (
        [Parameter(Mandatory = $true)][string] $DatabaseFilename,
        [Parameter(Mandatory = $false)][string] $DatabasePath,
        [Parameter(Mandatory = $false)][string] $DatabaseName,
        [Parameter(Mandatory = $false)][string] $KeyFileFilename,
        [Parameter(Mandatory = $true)][string] $MasterPassword,
        [Parameter(Mandatory = $false)][string] $Group = "/Breakglass",
        [Parameter(Mandatory = $false)][string] $FilePasswordGroup = "/FilePassword",
        [Parameter(Mandatory = $false)][string] $KeePassProgram = "c:\program files\Keepassxc\keepassxc-cli.exe",
        [Parameter(Mandatory = $false)][switch] $CreateDatabase = $false,

        [Parameter(Mandatory = $false)][switch] $Quiet = $false,
        [Parameter(Mandatory = $false)][switch] $WhatIf = $false
    )

    process {

        if (Test-Path -Path $KeePassProgram) {
            # KeePassXC-cli.exe is found
            #
            # Verify that it is available in system path
            # If not found in Path, update path
            #
            $keePassExec = Split-Path $KeePassProgram -Leaf
            if ((Get-Command $keePassExec -ErrorAction SilentlyContinue) -eq $null) {
                $keePassPath = Split-Path $KeePassProgram -Parent

                if ($env:Path -notcontains $keePassPath) {
                    if (-not $Quiet) { Write-Log "Adding '$keePassPath' to PATH" -Level Debug }
                    $env:Path = $env:Path + ";" + $keePassPath
                }
            }
        }
        else {
            # KeePassXC-cli program not found
            $msg = "keepassxc-cli.exe is not found"
            if (-not $Quiet) { Write-Log $msg -Level Warning }
            throw (New-Object KeePassXCException($EXCEPTION_NOT_FOUND, $msg))
        }

        if (-not $createDatabase) {
            #
            # database and key file must exist
            #
            if (-not (Test-Path -Path $DatabaseFilename)) {
                $msg = "Database file is not found '$DatabaseFilename'"
                if (-not $Quiet) { Write-Log $msg -Level Warning }
                throw (New-Object KeePassXCException($EXCEPTION_NOT_FOUND, $msg))
            }

            if ($KeyFileFilename -and -not (Test-Path -Path $KeyFileFilename)) {
                $msg = "Key file is not found '$KeyFileFilename'"
                if (-not $Quiet) { Write-Log $msg -Level Warning }
                throw (New-Object KeePassXCException($EXCEPTION_NOT_FOUND, $msg))
            }
        }


        if ($createDatabase -and (-not (Test-Path -Path $DatabaseFilename) -or ($KeyFileFilename -and -not (Test-Path -Path $KeyFileFilename)))) {
            #
            # Either database or keyfile (or both) is missing, remove the other
            # Create new database
            #
            if (Test-Path -Path $DatabaseFilename) {
                try {
                    if ($WhatIf) {
                        Write-Log "WhatIf: Removing database file '$DatabasePath'" -Level Debug
                    }
                    else {
                        Remove-Item -Path $DatabaseFilename -ErrorAction Stop
                        if (-not $Quiet) { Write-Log "Removed existing database file '$DatabaseFilename'" -Level Debug }
                    }
                }
                catch {
                    $msg = "Insufficient permissions to remove file '$DatabaseFilename'"
                    throw (New-Object KeePassXCException($EXCEPTION_NOT_AUTHORIZED, $msg))
                }
            }
            else {
                $checkPath = Split-Path $DatabaseFilename -Parent
                if (-not (Test-Path -Path $checkPath)) {
                    $msg = "The path specified is not found '$DatabaseFilename'"
                    if (-not $Quiet) { Write-Log $msg -Level Warning }
                    throw (New-Object KeePassXCException($EXCEPTION_NOT_FOUND, $msg))
                }
            }

            if ($KeyFileFilename) {
                if (Test-Path -Path $KeyFileFilename) {
                    try {
                        if ($WhatIf) {
                            Write-Log "WhatIf: Removing KeyFile '$KeyFileFilename'" -Level Debug
                        }
                        else {
                            Remove-Item -Path $KeyFileFilename -ErrorAction Stop
                            if (-not $Quiet) { Write-Log "Removed existing key file '$KeyFileFilename'" -Level Debug }
                        }
                    }
                    catch {
                        $msg = "Insufficient permissions to remove file '$KeyFileFilename'"
                        throw (New-Object KeePassXCException($EXCEPTION_NOT_AUTHORIZED, $msg))
                    }
                }
                else {
                    $checkPath = Split-Path $KeyFileFilename -Parent
                    if (-not (Test-Path -Path $checkPath)) {
                        $msg = "The path specified is not found '$KeyFileFilename'"
                        if (-not $Quiet) { Write-Log $msg -Level Warning }
                        throw (New-Object KeePassXCException($EXCEPTION_NOT_FOUND, $msg))
                    }
                }
                $res = New-KeePassXCDatabase -DatabaseFilename $DatabaseFilename -KeyFileFilename $KeyFileFilename -MasterPassword $MasterPassword -Quiet:$Quiet -WhatIf:$WhatIf
                if (-not $Quiet) { Write-Log "Created database database '$DatabaseFilename'" -Level Debug }
            }
            else {
                $res = New-KeePassXCDatabase -DatabaseFilename $DatabaseFilename -MasterPassword $MasterPassword -Quiet:$Quiet -WhatIf:$WhatIf
                if (-not $Quiet) { Write-Log "Created database database '$DatabaseFilename'" -Level Debug }
            }
        }

        if ($Group) {
            $Group= "/"+$Group.Trim(" /")
        }

        if ($FilePasswordGroup) {
            $FilePasswordGroup= "/"+$FilePasswordGroup.Trim(" /")
        }

        if (-not $DatabasePath.EndsWith('\')) {
            $DatabasePath += '\'
        }
        $Script:kpDatabasePath = $DatabasePath
        $Script:kpDatabaseName = $DatabaseName
        $Script:kpDatabaseFilename = $DatabaseFilename
        $Script:kpKeyFileFilename = $KeyFileFilename
        $Script:kpMasterPassword = $MasterPassword
        $Script:kpKeePassProgram = $KeePassProgram
        $Script:kpGroup = $Group
        $Script:kpFilePasswordGroup = $FilePasswordGroup
        $Script:kpInitialized = $true

        #
        # If a valid entry is found in "Recycle Bin" it is seen as
        # already available in KeePassXC.
        # Just remove "Recycle Bin"
        #
        if (Test-KeePassXCGroup -Group "/Recycle Bin") {
            if ($WhatIf) {
                Write-Log "Removing 'Recycle Bin'" -Level Info -ForegroundColor Green
            }
            else {
                $res = Remove-KeePassXCGroup -Group "/Recycle Bin"
                if (-not $Quiet) { Write-Log "Removed 'Recycle Bin'" -Level Debug }
            }
        }

        #
        # Now proceed without "Recycle Bin" being around
        #
        if ($Group) {
            if (-not $(Test-KeePassXCGroup -Group $Group)) {
                if ($WhatIf) {
                    Write-Log "Adding group '$Group'" -Level Info -ForegroundColor Green
                }
                else {
                    $res = New-KeePassXCGroup -Group $Group
                    if (-not $Quiet) { Write-Log "Added group '$Group'" -Level Debug }
                }
            }
        }

        if ($FilePasswordGroup) {
            if (-not $(Test-KeePassXCGroup -Group $FilePasswordGroup)) {
                if ($WhatIf) {
                    Write-Log "Adding group '$FilePasswordGroup'" -Level Info -ForegroundColor Green
                }
                else {
                    $res = New-KeePassXCGroup -Group $FilePasswordGroup
                    if (-not $Quiet) { Write-Log "Added group '$FilePasswordGroup'" -Level Debug }
                }
            }
        }
    }
}

# --- end-of-file ---