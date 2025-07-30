#--------------------------------------------------------------------------------------
function Update-PwsManagedAccountPassword () 
{
    Param(
        [Parameter(Mandatory=$true)][int] $AccountID,
        [Parameter(Mandatory=$false)][string] $Password
    )
    
	process {
        $body = @{ Queue= $false; }

        $res= PSafe-Post "ManagedAccounts/$AccountID/Credentials/Change" $body;
        return $res
    }
}

# --- end-of-file ---