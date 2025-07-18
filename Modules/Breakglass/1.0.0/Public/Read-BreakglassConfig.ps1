function Read-BreakglassConfig {
    param (
        [Parameter(Mandatory=$false)][string]$ConfigPath= "c:\temp"
    )
    #
    # Fetch credentials for KeePassXC and PAM
    #
    $runHostname= $([System.Net.DNS]::GetHostByName('').hostname).ToLower()

    $whoami= [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    $idx= $whoami.IndexOf("\")
    if ($idx -ge 0) { $whoami= $whoami.substring($whoami.IndexOf("\")+1) }

    if (Test-Path -Path $ConfigPath -PathType Container) {
        $ConfigPath+= "\Breakglass-XXXX.properties"
    }

    $finalConfig= New-Object System.Collections.Hashtable

    $configFile= $ConfigPath.replace("XXXX", "$($runHostname)_$($whoami)")
    if (Test-Path -Path $configFile) {
        $configJson= Get-Content -path $configFile

        $config= $configJson | ConvertFrom-Json

        $config | %{
            if ($_.type -eq "KeePassXC") {
                #
                # KeePassXC credentials and configuration
                #
                $securePwd = $($_.MasterPassword) | ConvertTo-SecureString
                $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePwd)
                $MasterPassword= [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

                <#
                if (-not $MasterPassword) {
                    # Prompt for the master password (securely)
                    $pw = Read-Host -Prompt "Enter KeePassXC master password" -AsSecureString
                    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pw)
                    $MasterPassword= [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                    [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
                }
                #>

                $finalConfig.Add("KeePassXC", [PSCustomObject]@{ DatabasePath= $_.DatabasePath; KeyFilePath= $_.KeyFilePath; Group= $_.Group; MasterPassword=$MasterPassword } )
            }

            if ($_.type -eq "PasswordSafe") {
                #
                # PAM API credentials and configuration
                #
                $securePwd = $($_.password) | ConvertTo-SecureString
                $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePwd)
                $pamApiPassword= [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

                $secureKey = $($_.ApiKey) | ConvertTo-SecureString
                $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureKey)
                $pamApiKey= [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
                [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

                #$Script:pamDNS= $_.DNS
                #$Script:pamApiUsername= $_.username
                #$Script:pamWorkgroup= $_.workgroup

                $finalConfig.Add("PasswordSafe", [PSCustomObject]@{ DNS= $_.DNS; username= $_.username; workgroup= $_.workgroup; apiKey=$pamApiKey; password=$pamApiPassword } )

            }
        }
    }

    return $finalConfig
}

# --- end-of-file ---