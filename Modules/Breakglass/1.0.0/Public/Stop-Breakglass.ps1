#--------------------------------------------------------------------------------------
# signout from API
function Stop-Breakglass ()
{
	#Write-PSFMessage -Level Debug ("Signout from BryondTrust")
	try
	{
		$res= Stop-PasswordSafe
		$res= Stop-KeePassXC
	}
	catch [System.Net.WebException]
	{
		throw;
	}
    finally {
        $Script:kpDatabasePath= ""
	    $script:kpKeyFilePath= ""
	    $Script:kpGroup= ""
	    $Script:kpMasterPassword= "*****************************************************"
        $Script:kpInitialized= $false
    }
}

# --- end-of-file ---