#--------------------------------------------------------------------------------------
function Update-SymTargetAccountPassword () 
{
    Param(
        [Parameter(Mandatory=$true)][int] $AccountID,
        [Parameter(Mandatory=$false)][string] $Password
    )
    
	process {

		try {
            $params = @{
                'TargetAccount.ID' = $AccountID
                'allowUnsynchronized' = "true"
                'TargetAccount.passwordVerified' = "false"
                }

            if ($password) {
                $params+= @{
                    'password'= $Password
                    'confirmPassword'= $Password
                }
            }

            $res= Invoke-SymantecCLI -Cmd "updateTargetAccountPassword" -Params $params

            $pwd= $res.'cr.result'.TargetAccount.password
            return $pwd
		}
        catch
        {
            throw
        }
    }
}

# --- end-of-file ---