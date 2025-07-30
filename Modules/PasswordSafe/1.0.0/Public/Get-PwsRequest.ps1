# No caching for this call
#
#$script:cacheRequestsBase= New-Object System.Collections.ArrayList
#$script:cacheRequestsByID= New-Object System.Collections.HashTable	# Index into cache array

enum REQUEST_STATUS {
	All
	Active
	Pending
}

function Get-PwsRequest () {

    Param(
		[Alias("RequestID")]
        [parameter(Mandatory=$false)][int] $ID= -1,
		
        [parameter(Mandatory=$false)][int] $AccountID= -1,
        [parameter(Mandatory=$false)][string] $AccountName,
        [parameter(Mandatory=$false)][int] $SystemID= -1,
        [parameter(Mandatory=$false)][string] $SystemName,

		[Parameter(Mandatory=$false)][REQUEST_STATUS] $Status = "Active",
		
        [Parameter(Mandatory=$false)][switch] $Single= $false,
        [Parameter(Mandatory=$false)][switch] $Refresh= $false,
        [Parameter(Mandatory=$false)][switch] $NoEmptySet= $false
    )
    
	process {
		try {
			#
			# No-caching
			#
            $res = PSafe-Get "Requests";

            # filter
            if ($ID -ge 0) {$res= $res | Where-Object {$_.RequestID -like $ID}}
			if ($accountID -ge 0) {$res= $res | Where-Object {$_.AcocuntID -like $AccountID}}
			if ($accountName) {$res= $res | Where-Object {$_.AccountName -like $AccountName}}
			if ($SystemID -ge 0) {$res= $res | Where-Object {$_.SystemID -like $SystemID}}
			if ($systemName) {$res= $res | Where-Object {$_.ManagedSystemName -like $SystemName}}             # Must use $_.ManagedSystemName here
			if ($Status -ne "All") {$res= $res | Where-Object {$_.Status -eq $Status}}

			$res | %{
				$_= _Normalize-Request($_)
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
            if ($_.Exception.GetType().FullName -eq "PasswordSafeException") {throw}

            if ($_.Exception.GetType().FullName -eq "System.Net.WebException" -and $_.Exception.Response.StatusCode -eq 404) {
                #404 not found
                $details= $DETAILS_REQUEST_01
                throw ( New-Object PasswordSafeException( $EXCEPTION_NOT_FOUND, $details ) )
            }

            throw
        }
    }
}

# --- end-of-file ---