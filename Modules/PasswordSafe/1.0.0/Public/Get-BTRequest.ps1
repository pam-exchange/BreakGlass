# No caching for this call
#
$script:cacheRequestsBase= New-Object System.Collections.ArrayList
$script:cacheRequestsByID= New-Object System.Collections.HashTable	# Index into cache array

enum REQUEST_STATUS {
	All
	Active
	Pending
}

function Get-BTRequest () {

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
        #Write-PSFMessage -Level Debug "Start -- ID='$($ID)', Name='$($Name)', Single='$($Single)', Refresh='$($Refresh)', NoEmptySet='$($NoEmptySet)'"

		try {

<#
			#
			# Fetch and build cache
			#

			if ($refresh -or -not $Script:cacheRequestsBase) {
				$script:cacheRequestsBase.Clear()
				$script:cacheRequestsByID.Clear()

				# Write-PSFMessage -Level Debug "fetch multiple"
				$res = PSafe-Get "Requests";
				$res | %{
					$tmp= _Normalize-Request($_)

					$key= $tmp.ID
					$idx= $script:cacheRequestsBase.Add( $tmp ) 
					$script:cacheRequestsByID.Add( $key, $idx ) | Out-Null	# External ID into array idx
				}
			}
			

			#
			# Apply filter
			#
            if ($ID -ge 0) 
            {
				$idx= $Script:cacheRequestsByID[ [int]$ID ]		# External ID to array idx
				$res= $Script:cacheRequestsBase[ [int]$idx ]
            }
			else {
				$res= $Script:cacheRequestsBase
				if ($AccountID -ge 0 -or $AccountName -or $SystemID -ge 0 -or $SystemName -or $Status -ne "All") 
				{
                    # filter
					if ($accountID -ge 0) {$res= $res | Where-Object {$_.AcocuntID -like $AccountID}}
					if ($accountName) {$res= $res | Where-Object {$_.AccountName -like $AccountName}}
					if ($SystemID -ge 0) {$res= $res | Where-Object {$_.SystemID -like $SystemID}}
					if ($systemName) {$res= $res | Where-Object {$_.ManagedSystemName -like $SystemName}}             # Must use $_.ManagedSystemName here}
					if ($Status -ne "All") {$res= $res | Where-Object {$_.Status -eq $Status}}
				}
			}
			
            #
            # Remove request already expired
            #
            $now= Get-Date
            $res= $res | Where-Object {$now -lt [DateTime]$($_.ExpiresDate)}

#>

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
# End - no-caching
# 

			#
			# Check boundary conditions
			#
            if ($NoEmptySet -and $res.Count -eq 0) {
                $details= $EXCEPTION_NOT_FOUND_DETAILS
                #Write-PSFMessage -Level Error "Message= '$EXCEPTION_NOT_FOUND', Details= '$($details)'"
                throw ( New-Object PasswordSafeException( $EXCEPTION_NOT_FOUND, $details ) )
            }

            if ($single -and $res.Count -ne 1) {
                # More than one managed system found with -single option 
                $details= $EXCEPTION_NOT_SINGLE_DETAILS
                #Write-PSFMessage -Level Error "Get-BTManagedSystem: Message= '$EXCEPTION_INVALID_PARAMETER', Details= '$($details)'"
                throw ( New-Object PasswordSafeException( $EXCEPTION_NOT_SINGLE, $details ) )
            }

            #Write-PSFMessage -Level Debug "Found $($res2.Count) assets (filtered)"
            return $res
		}
        catch
        {
            if ($_.Exception.GetType().FullName -eq "PasswordSafeException") {throw}

            if ($_.Exception.GetType().FullName -eq "System.Net.WebException" -and $_.Exception.Response.StatusCode -eq 404) {
                #404 not found
                $details= $DETAILS_REQUEST_01
                #Write-PSFMessage -Level Error "Message= '$EXCEPTION_NOT_FOUND', Details= '$($details)'"
                throw ( New-Object PasswordSafeException( $EXCEPTION_NOT_FOUND, $details ) )
            }

            # something else happened
            #Write-PSFMessage -Level Error ("Exception - Type= $($_.Exception.GetType().FullName), Message= $($_.Exception.Message), Details= $($_.ErrorDetails)")
            throw
        }
    }
}

# --- end-of-file ---