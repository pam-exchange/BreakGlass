#--------------------------------------------------------------------------------------
function Get-SymTargetAccountPassword () 
{
    Param(
        [Parameter(Mandatory=$true)][int] $AccountID,
        [Parameter(Mandatory=$false)][string] $Reason= "Breakglass"
    )
    
	process {

		try {
            $params = @{
                'TargetAccount.ID' = $AccountID
                reason = $reason
                reasonDetails = $reason
                }

            $res= Invoke-SymantecCLI -Cmd "viewAccountPassword" -Params $params

            $pwd= $res.'cr.result'.TargetAccount.password
            return $pwd
		}
        catch
        {
            #Write-Host $e_.Exception
            throw
        }
    }
}

# --- end-of-file ---