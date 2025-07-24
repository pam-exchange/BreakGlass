<#
enum PAM_TYPE {
	PasswordSafe
    SymantecPAM
}

enum VAULT_TYPE {
	KeePassXC
}
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