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
function Start-Breakglass (
    [Parameter(Mandatory=$false)][PAM_TYPE] $PAMType= "PasswordSafe",
    [Parameter(Mandatory=$false)][VAULT_TYPE] $VaultType= "KeePassXC",
    [Parameter(Mandatory=$false)][string]$ConfigPath= "c:\temp"
)
{
	#Write-PSFMessage -Level Debug ("Start-BeyondTrust: start")

    $config= Read-BreakglassConfig -ConfigPath $ConfigPath


    $Script:PAMType= $PAMType
    switch ($PAMType) 
    {
        "PasswordSafe" 
        {
            $Login= @{
                apiDNS= $config[ "PasswordSafe" ].DNS;
                apiKey= $config[ "PasswordSafe" ].apiKey;
                apiUsername= $config[ "PasswordSafe" ].username;
                apiPassword= $config[ "PasswordSafe" ].password;
                apiWorkgroup= $config[ "PasswordSafe" ].Workgroup;
            }
            $res= Start-PasswordSafe @Login
        }

        "SymantecPAM" 
        {
            #
            # Login to PAM with credentials from Credentials file
            #
            $Login= @{
                cliDNS= $config[ "SymantecPAM" ].DNS;
                cliUsername= $config[ "SymantecPAM" ].username;
                cliPassword= $config[ "SymantecPAM" ].password;
                cliPageSize= 100000;
            }
            $res= Start-SymantecPAM @Login
        }
    }



    $Script:VaultType= $VaultType
    switch ($VaultType) 
    {
        "KeePassXC"
        {
            $Script:kpDatabasePath= $config[ "KeePassXC" ].databasePath
	        $script:kpKeyFilePath= $config[ "KeePassXC" ].KeyFilePath
	        $Script:kpGroup= $config[ "KeePassXC" ].Group
	        $Script:kpMasterPassword= $config[ "KeePassXC" ].MasterPassword
            $Script:kpInitialized= $false

            $Login= @{
                databasePath= $config[ "KeePassXC" ].databasePath;
                KeyFilePath= $config[ "KeePassXC" ].KeyFilePath;
                Group= $config[ "KeePassXC" ].Group;
                MasterPassword= $config[ "KeePassXC" ].MasterPassword;
            }
            $res= Start-KeePassXC @Login
        }
    }
}

# --- end-of-file ---