#--------------------------------------------------------------------------------------
function Get-BTManagedAccountPassword () 
{
    Param(
		[Alias("RequestID")]
        [Parameter(Mandatory=$true)][int] $ID
    )
    
	process {
        #Write-PSFMessage -Level Debug "Start -- RequestID='$($RequestID)'"

		try {
			$pwd= PSafe-Get "Credentials/$($ID)";
            return $pwd
		}
        catch
        {
            if ($_.Exception.GetType().FullName -eq "PasswordSafeException") {throw}

            if ($_.Exception.GetType().FullName -eq "System.Net.WebException" -and $_.Exception.Response.StatusCode -eq 404) {
                if ($_.ErrorDetails.Message -match "Request has been released or is expired") {
                    $details= $DETAILS_MANAGEDACCOUNTPASSWORD_01
                    throw ( New-Object PasswordSafeException( $EXCEPTION_NOT_FOUND, $details ) )
                }
                throw ( New-Object PasswordSafeException( $EXCEPTION_NOT_FOUND ) )
            }
            throw
        }
    }
}

# --- end-of-file ---