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
function Start-Breakglass {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [PAM_TYPE] $PAMType = "PasswordSafe",

        [Parameter(Mandatory = $false)]
        [VAULT_TYPE] $VaultType = "KeePassXC",

        [Parameter(Mandatory = $false)]
        [string] $ConfigPath = "c:\temp"
    )

    $config = Read-BreakglassConfig -ConfigPath $ConfigPath

    $Script:PAMType = $PAMType
    switch ($PAMType) {
        "PasswordSafe" {
            $Login = @{
                ApiDNS       = $config["PasswordSafe"].DNS
                ApiKey       = $config["PasswordSafe"].apiKey
                ApiUsername  = $config["PasswordSafe"].username
                ApiPassword  = $config["PasswordSafe"].password
                ApiWorkgroup = $config["PasswordSafe"].workgroup
            }
            $res = Start-PasswordSafe @Login
        }

        "SymantecPAM" {
            #
            # Login to PAM with credentials from Credentials file
            #
            $Login = @{
                CliDNS      = $config["SymantecPAM"].DNS
                CliUsername = $config["SymantecPAM"].username
                CliPassword = $config["SymantecPAM"].password
                CliPageSize = 100000
            }
            $res = Start-SymantecPAM @Login
        }
    }

    $Script:VaultType = $VaultType
    switch ($VaultType) {
        "KeePassXC" {
            $kpDatabasePath = $config["KeePassXC"].DatabasePath
            if (!$kpDatabasePath.EndsWith('\')) {
                $kpDatabasePath += '\'
            }
            $kpDatabaseName = $config["KeePassXC"].DatabaseName

            $Login = @{
                DatabasePath      = $kpDatabasePath
                DatabaseName      = $kpDatabaseName
                DatabaseFilename  = $kpDatabasePath + $kpDatabaseName + ".kdbx"
                KeyFileFilename   = $config["KeePassXC"].KeyFileFilename
                Group             = $(if ($config["KeePassXC"].Group) { $config["KeePassXC"].Group } else { "/BreakGlass" })
                FilePasswordGroup = $(if ($config["KeePassXC"].FilePasswordGroup) { $config["KeePassXC"].FilePasswordGroup } else { "/FilePassword" })
                MasterPassword    = $config["KeePassXC"].MasterPassword
            }
            $res = Start-KeePassXC @Login
        }
    }
}

# --- end-of-file ---
