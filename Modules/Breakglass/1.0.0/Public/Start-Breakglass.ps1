#--------------------------------------------------------------------------------------
function Start-Breakglass (
    [Parameter(Mandatory=$false)][string]$ConfigPath= "c:\temp"
)
{
	#Write-PSFMessage -Level Debug ("Start-BeyondTrust: start")

    $config= Read-BreakglassConfig -ConfigPath $ConfigPath

    #
    # Login to PAM with credentials from Credentials file
    #
    $LoginPasswordSafe= @{
        apiDNS= $config["PasswordSafe"].DNS;
        apiKey= $config["PasswordSafe"].apiKey;
        apiUsername= $config["PasswordSafe"].username;
        apiPassword= $config["PasswordSafe"].password;
        apiWorkgroup= $config["PasswordSafe"].Workgroup;
    }
    $res= Start-PasswordSafe @LoginPasswordSafe

    #
    # KeePassXC credentials
    #
    $Script:kpDatabasePath= $config["KeePassXC"].databasePath
	$script:kpKeyFilePath= $config["KeePassXC"].KeyFilePath
	$Script:kpGroup= $config["KeePassXC"].Group
	$Script:kpMasterPassword= $config["KeePassXC"].MasterPassword
    $Script:kpInitialized= $false

    $LoginKeePassXC= @{
        databasePath= $config["KeePassXC"].databasePath;
        KeyFilePath= $config["KeePassXC"].KeyFilePath;
        Group= $config["KeePassXC"].Group;
        MasterPassword= $config["KeePassXC"].MasterPassword;
    }
    $res= Start-KeePassXC @LoginKeePassXC
}

# --- end-of-file ---