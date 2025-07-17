#--------------------------------------------------------------------------------------
# signout from API
function Stop-KeePassXC ()
{
    $Script:kpDatabasePath= ""
    $Script:kpKeyFilePath= ""
	$Script:kpKeePassProgram= ""
	$Script:kpMasterPassword= "*****************************************************"
    $Script:kpInitialized= $false
}

# --- end-of-file ---