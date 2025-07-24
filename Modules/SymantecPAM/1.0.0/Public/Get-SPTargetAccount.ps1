$script:cacheTargetAccountBase= New-Object System.Collections.ArrayList
$script:cacheTargetAccountByID= New-Object System.Collections.HashTable		# Index into cache array

enum DETAILS {
    COMPACT
    FULL
}


#--------------------------------------------------------------------------------------
function Get-SPTargetAccount () 
{
    Param(
		[Alias("AccountID")]
        [Parameter(Mandatory=$false)][int] $ID= -1,
		
		[Alias("AccountName")]
        [Parameter(Mandatory=$false)][string] $Name,

        [Parameter(Mandatory=$false)][int] $SystemID= -1,			# Filter by ManagedSystem ID
        [Parameter(Mandatory=$false)][string] $SystemName,			# Filter by ManagedSystem Name
        

        [Parameter(Mandatory=$false)][DETAILS] $details= "COMPACT",

        [Parameter(Mandatory=$false)][switch] $Single= $false,
		[Parameter(Mandatory=$false)][switch] $Refresh= $false,
        [Parameter(Mandatory=$false)][switch] $NoEmptySet= $false
    )
    
	process {
		try {
            $res= Invoke-SymantecCLI -cmd "listTargetAccounts"

            $result= $res.'cr.result'.'c.cw.m.tacs'
            $res= $result | ForEach-Object {[PSCustomObject]@{TargetServerID=$_.'ts.id'; TargetServerName=$_.hn; TargetapplicationID=$_.'ta.id'; TargetapplicationName=$_.na; TargetAccountID=$_.'bm.id'; TargetAccountName=$_.un}}


			#
			# Check boundary conditions
			#
            if ($NoEmptySet -and $res.Count -eq 0) {
                $details= $DETAILS_EXCEPTION_NOT_FOUND_01
                #Write-PSFMessage -Level Error "Message= '$EXCEPTION_NOT_FOUND', Details= '$($details)'"
                throw ( New-Object PasswordSafeException( $EXCEPTION_NOT_FOUND, $details ) )
            }

            if ($single -and $res.Count -ne 1) {
                # More than one managed system found with -single option 
                $details= $DETAILS_EXCEPTION_NOT_SINGLE_01
                #Write-PSFMessage -Level Error "Get-BTManagedSystem: Message= '$EXCEPTION_INVALID_PARAMETER', Details= '$($details)'"
                throw ( New-Object PasswordSafeException( $EXCEPTION_NOT_SINGLE, $details ) )
            }

            #Write-PSFMessage -Level Debug "Found $($res2.Count) ManagedAccount (filtered)"
            return $res
		}
        catch
        {
            throw
        }
    }
}

# --- end-of-file ---