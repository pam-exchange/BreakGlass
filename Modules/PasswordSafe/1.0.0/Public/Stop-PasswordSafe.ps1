#--------------------------------------------------------------------------------------
# signout from API
function Stop-PasswordSafe ()
{
	#Write-PSFMessage -Level Debug ("Signout from BryondTrust")
	try
	{
		$res= PSafe-Post "Auth/Signout"		
	}
	catch [System.Net.WebException]
	{
		throw;
	}
}

# --- end-of-file ---