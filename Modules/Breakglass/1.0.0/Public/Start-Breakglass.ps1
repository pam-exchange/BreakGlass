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
    param (
        [Parameter(Mandatory = $false)][PAM_TYPE] $PAMType = "PasswordSafe",
        [Parameter(Mandatory = $false)][VAULT_TYPE] $VaultType = "KeePassXC",
        [Parameter(Mandatory = $false)][string] $ConfigPath = "c:\temp"
    )

    $config = Read-BreakglassConfig -ConfigPath $ConfigPath

    $Script:PAMType = $PAMType
    switch ($PAMType) {
        "PasswordSafe" {
            $loginParams = @{
                apiDNS       = $config["PasswordSafe"].DNS;
                apiKey       = $config["PasswordSafe"].apiKey;
                apiUsername  = $config["PasswordSafe"].username;
                apiPassword  = $config["PasswordSafe"].password;
                apiWorkgroup = $config["PasswordSafe"].Workgroup;
            }
            $res = Start-PasswordSafe @loginParams
        }

        "SymantecPAM" {
            #
            # Login to PAM with credentials from Credentials file
            #
            $loginParams = @{
                cliDNS      = $config["SymantecPAM"].DNS;
                cliUsername = $config["SymantecPAM"].username;
                cliPassword = $config["SymantecPAM"].password;
                cliPageSize = 100000;
            }
            $res = Start-SymantecPAM @loginParams
        }
    }

    $Script:VaultType = $VaultType
    switch ($VaultType) {
        "KeePassXC" {
            $kpDatabasePath = $config["KeePassXC"].DatabasePath
            if (-not $kpDatabasePath.EndsWith('\')) {
                $kpDatabasePath += '\'
            }
            $kpDatabaseName = $config["KeePassXC"].DatabaseName

            $loginParams = @{
                databasePath      = $kpDatabasePath;
                databaseName      = $kpDatabaseName;
                databaseFilename  = $kpDatabasePath + $kpDatabaseName + ".kdbx";
                KeyFileFilename   = $config["KeePassXC"].KeyFileFilename;
                Group             = $(if ($config["KeePassXC"].Group) { $config["KeePassXC"].Group } else { "/BreakGlass" });
                FilePasswordGroup = $(if ($config["KeePassXC"].FilePasswordGroup) { $config["KeePassXC"].FilePasswordGroup } else { "/FilePassword" });
                MasterPassword    = $config["KeePassXC"].MasterPassword;
            }
            $res = Start-KeePassXC @loginParams -CreateDatabase
        }
    }
}

# --- end-of-file ---