$script:cacheTargetAccountBase= New-Object System.Collections.ArrayList
$script:cacheTargetAccountByID= New-Object System.Collections.HashTable		# Index into cache array

enum DETAILS {
    COMPACT
    FULL
}


#--------------------------------------------------------------------------------------
function Get-SymTargetAccount () 
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

            if ($details -eq "COMPACT") {

                $res= Invoke-SymantecCLI -cmd "listTargetAccounts"

                $result= $res.'cr.result'.'c.cw.m.tacs'
                $res= $result | ForEach-Object {[PSCustomObject]@{TargetServerID=$_.'ts.id'; TargetServerName=$_.hn; TargetapplicationID=$_.'ta.id'; TargetapplicationName=$_.na; TargetAccountID=$_.'bm.id'; TargetAccountName=$_.un; Verified=([System.convert]::ToBoolean($_.pv))}}

            }
            else {
                #
                # TO-DO: Detailed TargetAccount
                # Fetch TargetApplication and TargetServer
                [System.Collections.ArrayList]$res = @()
            }

			#
			# Check boundary conditions
			#
            if ($res -eq $null) {$cnt= 0}
            elseif ($res.GetType().Name -eq "PSCustomObject") {$cnt= 1} else {$cnt= $res.count}

            if ($NoEmptySet -and $cnt -eq 0) {
                $details= $DETAILS_EXCEPTION_NOT_FOUND_01
                throw ( New-Object PasswordSafeException( $EXCEPTION_NOT_FOUND, $details ) )
            }

            if ($single -and $cnt -ne 1) {
                # More than one managed system found with -single option 
                $details= $DETAILS_EXCEPTION_NOT_SINGLE_01
                throw ( New-Object PasswordSafeException( $EXCEPTION_NOT_SINGLE, $details ) )
            }

            return $res
		}
        catch
        {
            throw
        }
    }
}

# --- end-of-file ---