$version= "1.0.0"

$configKeePassXC= @{
        type="KeePassXC"; 
		DatabasePath= "c:\temp\BreakGlass.kdbx"; 
		KeyFilePath= "c:\temp\BreakGlass.keyfile"; 
		MasterPassword= "Admin4cspm!"; 
        Group= "BreakGlass";
    }

$configAPI = @{
        type="API"; 
		domain= "cwpws.ps.beyondtrustcloud.com"; 
		shortDomain= "beyondtrustcloud"; 
		DNS= "cwpws.ps.beyondtrustcloud.com";
        pamHostname= "cwpws";
		username= "api_Breakglass"; 
		password= "Admin4cspm!1234!"; 
		apiKey= "4ef96448db2aaf8f09b9b25614245bb498d8fe284a66ce3ddaeab8620200afc3699f8c6e630bcdce15f6ff02ce6ec09926196706953e862f0efd03ddcd5af146";
        Workgroup= "Default Workgroup";
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
    # prepare configKeePassXC
    #
    $securePassword= $configAPI.password | ConvertTo-SecureString -AsPlainText -Force 
    $configAPI.password= $securePassword | ConvertFrom-SecureString 

    $securePassword= $configAPI.apiKey | ConvertTo-SecureString -AsPlainText -Force 
    $configAPI.apiKey= $securePassword | ConvertFrom-SecureString 

    $config= New-Object System.Collections.ArrayList
    $config.add( $configKeePassXC )| Out-Null
    $config.add( $configAPI )| Out-Null
    
    $configJson= $config | ConvertTo-Json

    $outFilename= "c:\Temp\Breakglass-$($runHostname)_$($whoami).properties"
    Write-Host "Write configuration to '$outFilename'"
    $configJson | Out-file -FilePath $outFilename -Encoding ascii
} 
catch {
    Write-Error "Expected exception received, Name= $($_.Exception.Message), details= $($_.Exception.Details)"
}
