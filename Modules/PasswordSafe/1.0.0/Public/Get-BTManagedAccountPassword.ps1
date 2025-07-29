#--------------------------------------------------------------------------------------
function Get-BTManagedAccountPassword () 
{
    Param(
        [Parameter(Mandatory=$true)][int] $RequestID,
        [Parameter(Mandatory=$false)][switch]$useDSS
    )
    
	process {
		try {

            if ($useDSS) {
                $pwd= PSafe-Get "Credentials/$($RequestID)?type=dsskey"
            }
            else {
			    $pwd= PSafe-Get "Credentials/$($RequestID)"
            }
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