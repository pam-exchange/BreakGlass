$version= "1.0.0"

$configKeePassXC= @{
        type="KeePassXC"; 
		DatabasePath= "c:\temp\BreakGlass.kdbx"; 
  		# KeyFilePath= "c:\temp\BreakGlass.keyfile";           # optional
		MasterPassword= "<SuperSecretPassword>"; 
        Group= "BreakGlass";
    }

$configPasswordSafe = @{
        type="PasswordSafe"; 
		DNS= "<dns name for Password Safe>";
		username= "api_Breakglass"; 
		password= "Kuxxxxxxxxxxxxxxxxxxxxxxxxxxmq3T!"; 
		apiKey= "4ef9xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx284a66ce3";
        Workgroup= "Default Workgroup";
    }

$configSymantecPAM = @{
        type="SymantecPAM"; 
		DNS= "<dns name for Symantec PAM>";
		username= "cli_breakglass"; 
		password= "<AnotherSecretPassword>"; 
    }

try {
    Write-Host "Credentials start, version=$($version) -----------------------------------"

    $runHostname= $([System.Net.DNS]::GetHostByName('').hostname).ToLower()
    Write-Host "runHostname= $runHostname"

    $whoami= [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

    $idx= $whoami.IndexOf("\")
    if ($idx -ge 0) {
        $whoami= $whoami.substring($whoami.IndexOf("\")+1)
    }
    Write-Host "WhoAmI= $whoami"

    #
    # prepare configKeePassXC
    #
    $securePassword= $configKeePassXC.MasterPassword | ConvertTo-SecureString -AsPlainText -Force 
    $configKeePassXC.MasterPassword= $securePassword | ConvertFrom-SecureString 

    #
    # prepare configPasswordSafe
    #
    $securePassword= $configPasswordSafe.password | ConvertTo-SecureString -AsPlainText -Force 
    $configPasswordSafe.password= $securePassword | ConvertFrom-SecureString 

    $securePassword= $configPasswordSafe.apiKey | ConvertTo-SecureString -AsPlainText -Force 
    $configPasswordSafe.apiKey= $securePassword | ConvertFrom-SecureString 

    #
    # prepare configSymantecPAM
    #
    $securePassword= $configSymantecPAM.password | ConvertTo-SecureString -AsPlainText -Force 
    $configSymantecPAM.password= $securePassword | ConvertFrom-SecureString 

    #
    # Convert to Json and save to file
    # 
    $config= New-Object System.Collections.ArrayList
    $config.add( $configKeePassXC ) | Out-Null
    $config.add( $configPasswordSafe ) | Out-Null
    $config.add( $configSymantecPAM ) | Out-Null
    
    $configJson= $config | ConvertTo-Json

    $outFilename= "c:\Temp\Breakglass-$($runHostname)_$($whoami).properties"
    Write-Host "Write configuration to '$outFilename'"
    $configJson | Out-file -FilePath $outFilename -Encoding ascii
} 
catch {
    Write-Error "Expected exception received, Name= $($_.Exception.Message), details= $($_.Exception.Details)"
}
