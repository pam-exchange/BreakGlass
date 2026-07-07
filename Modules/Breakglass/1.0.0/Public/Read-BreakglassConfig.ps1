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
function Read-BreakglassConfig {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string] $ConfigPath = "c:\temp"
    )

    #
    # Fetch credentials for KeePassXC and PAM
    #
    $runHostname = [System.Net.Dns]::GetHostName().ToLower()

    $whoami = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $idx = $whoami.IndexOf("\")
    if ($idx -ge 0) { $whoami = $whoami.Substring($whoami.IndexOf("\") + 1) }

    if (Test-Path -Path $ConfigPath -PathType Container) {
        $ConfigPath += "\Breakglass-XXXX.properties"
    }

    $finalConfig = @{}

    $configFile = $ConfigPath.Replace("XXXX", "$($runHostname)_$($whoami)")
    if (Test-Path -Path $configFile) {
        $configJson = Get-Content -Path $configFile

        $config = $configJson | ConvertFrom-Json

        $config | ForEach-Object {
            if ($_.type -eq "KeePassXC") {
                #
                # KeePassXC credentials and configuration
                #
                $secureMasterPassword = $($_.MasterPassword) | ConvertTo-SecureString

                $finalConfig.Add("KeePassXC", [PSCustomObject]@{
                        DatabasePath      = $_.DatabasePath
                        DatabaseName      = $_.DatabaseName
                        KeyFileFilename   = $_.KeyFileFilename
                        Group             = $_.Group
                        FilePasswordGroup = $_.FilePasswordGroup
                        MasterPassword    = $secureMasterPassword
                    })
            }

            if ($_.type -eq "PasswordSafe") {
                #
                # PAM API credentials and configuration
                #
                $securePassword = $($_.password) | ConvertTo-SecureString
                $secureApiKey = $($_.apiKey) | ConvertTo-SecureString

                $finalConfig.Add("PasswordSafe", [PSCustomObject]@{
                        DNS       = $_.DNS
                        username  = $_.username
                        workgroup = $_.workgroup
                        apiKey    = $secureApiKey
                        password  = $securePassword
                    })
            }

            if ($_.type -eq "SymantecPAM") {
                #
                # PAM API credentials and configuration
                #
                $securePassword = $($_.password) | ConvertTo-SecureString

                $finalConfig.Add("SymantecPAM", [PSCustomObject]@{
                        DNS      = $_.DNS
                        username = $_.username
                        password = $securePassword
                    })
            }
        }
    }

    return $finalConfig
}

# --- end-of-file ---