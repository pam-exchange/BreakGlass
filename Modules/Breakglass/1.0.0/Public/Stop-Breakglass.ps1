#--------------------------------------------------------------------------------------
# signout from API
function Stop-Breakglass ()
{
	#Write-PSFMessage -Level Debug ("Signout from BryondTrust")
	try
	{
        switch ($script:PAMType) {
            "PasswordSafe" 
            {
    		    $res= Stop-PasswordSafe
            }
            "SymantecPAM"
            {
                $res= Stop-SymantecPAM
            }
        }

        switch ($Script:VaultType) {
            "KeePassXC"
            {
        		$res= Stop-KeePassXC
            }
        }
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