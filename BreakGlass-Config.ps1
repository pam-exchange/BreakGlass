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

$version= "1.0.0"

$configKeePassXC= @{
        type="KeePassXC"; 
		DatabasePath= "c:\temp\"; 
		DatabaseName= "Breakglass"
  		# KeyFileFilename= "c:\temp\BreakGlass.keyfile";           # optional
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
