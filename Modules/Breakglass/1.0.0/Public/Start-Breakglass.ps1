#--------------------------------------------------------------------------------------
function Start-Breakglass (
    [Parameter(Mandatory=$false)][string]$ConfigPath= "c:\temp"
)
{
	#Write-PSFMessage -Level Debug ("Start-BeyondTrust: start")

    $config= Read-BGConfig -ConfigPath $ConfigPath

    #
    # Login to PAM with credentials from Credentials file
    #
    $LoginPasswordSafe= @{
        apiDomain= $config["API"].DNS;
        apiKey= $config["API"].apiKey;
        apiUsername= $config["API"].username;
        apiPassword= $config["API"].password;
        apiWorkgroup= $config["API"].Workgroup;
    }
    $res= Start-PasswordSafe @LoginPasswordSafe


    
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