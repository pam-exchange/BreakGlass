$version = "1.0.0"

$configKeePassXC = @{
    type              = "KeePassXC"
    DatabasePath      = "c:\temp\"
    DatabaseName      = "BreakGlass"
    #KeyFileFilename= "c:\temp\BreakGlass.keyfile";
    MasterPassword    = "xxxxx"
    Group             = "BreakGlass"
    FilePasswordGroup = "FilePassword"
}

$configPasswordSafe = @{
    type      = "PasswordSafe"
    DNS       = "xxxx.example.com"
    username  = "api_Breakglass"
    password  = "Kuxxxxxxxxxmq3T!"
    apiKey    = "4ef9xxxxxxxxxxxxx3ddcd5af146"
    Workgroup = "Default Workgroup"
}

$configSymantecPAM = @{
    type     = "SymantecPAM"
    DNS      = "192.168.242.5"
    username = "cli_breakglass"
    password = "xxxxx"
}

try {
    Write-Log -Message "Credentials start, version=$($version) -----------------------------------" -Level Info

    $runHostname = [System.Net.Dns]::GetHostName().ToLower()
    Write-Log -Message "runHostname= $runHostname" -Level Info

    $whoami = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

    $idx = $whoami.IndexOf("\")
    if ($idx -ge 0) {
        $whoami = $whoami.Substring($whoami.IndexOf("\") + 1)
    }
    Write-Log -Message "WhoAmI= $whoami" -Level Info

    #
    # prepare configKeePassXC
    #
    $securePassword = $configKeePassXC.MasterPassword | ConvertTo-SecureString -AsPlainText -Force
    $configKeePassXC.MasterPassword = $securePassword | ConvertFrom-SecureString

    #
    # prepare configPasswordSafe
    #
    $securePassword = $configPasswordSafe.password | ConvertTo-SecureString -AsPlainText -Force
    $configPasswordSafe.password = $securePassword | ConvertFrom-SecureString

    $securePassword = $configPasswordSafe.apiKey | ConvertTo-SecureString -AsPlainText -Force
    $configPasswordSafe.apiKey = $securePassword | ConvertFrom-SecureString

    #
    # prepare configSymantecPAM
    #
    $securePassword = $configSymantecPAM.password | ConvertTo-SecureString -AsPlainText -Force
    $configSymantecPAM.password = $securePassword | ConvertFrom-SecureString

    #
    # Convert to Json and save to file
    #
    $config = New-Object System.Collections.ArrayList
    $config.Add($configKeePassXC) | Out-Null
    $config.Add($configPasswordSafe) | Out-Null
    $config.Add($configSymantecPAM) | Out-Null

    $configJson = $config | ConvertTo-Json

    $outFilename = "c:\Temp\Breakglass-$($runHostname)_$($whoami).properties"
    Write-Log -Message "Write configuration to '$outFilename'" -Level Info
    $configJson | Out-File -FilePath $outFilename -Encoding ascii
}
catch {
    Write-Log -Message "Expected exception received, Name= $($_.Exception.Message), details= $($_.Exception.Details)" -Level Error
}
