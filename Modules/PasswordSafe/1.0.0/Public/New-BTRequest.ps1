#
# Cache is defined in Get-BTRequest
#
# $script:cacheRequestsBase= New-Object System.Collections.ArrayList
# $script:cacheRequestsByID= New-Object System.Collections.HashTable	# Index into cache array
#

function New-BTRequest () {

    Param(
        [parameter(Mandatory=$false)][int] $AccountID= -1,
        [parameter(Mandatory=$false)][string] $AccountName,
        [parameter(Mandatory=$false)][int] $SystemID= -1,
        [parameter(Mandatory=$false)][string] $SystemName,

        [parameter(Mandatory=$false)][int] $Duration= 1,
        [parameter(Mandatory=$false)][string] $Reason= "API CheckOut",
        [parameter(Mandatory=$false)][switch] $RotateOnCheckin= $false
    )
    
	process {
        #Write-PSFMessage -Level Debug "Start -- ID='$($ID)', Name='$($Name)', Single='$($Single)', Refresh='$($Refresh)', NoEmptySet='$($NoEmptySet)'"

		try {

            if ($SystemName -and -not $SystemID -ge 0) {
                $sys= Get-BTManagedSystem -Name $SystemName -Single
                $SystemID= $sys.Name
            }

            if ($AccountName -and -not $AccountID -ge 0) {
                $acc= Get-BTManagedAccount -Name $AccountName -SystemID $SystemID
                $AccountID= $acc.ID
            }

            $body = @{
                "AccessType"             = "View"
                "SystemID"               = $SystemID
                "AccountID"              = $AccountID
                "DurationMinutes"        = $Duration
                "Reason"                 = $Reason
                "AccessPolicyScheduleID" = $null
                "RotateOnCheckin"        = $RotateOnCheckin
            }

            try {

                $reqID = PSafe-Post "Requests" $body;
            
                <#
                TO-DO

                Update request cache to indicate that a request is available, but without details

				$req= Get-BTRequest -Refresh

                #>


            }
            catch {
                Throw "Error: $_"
            }

            return $reqID
		}
        catch
        {
            if ($_.Exception.GetType().FullName -eq "PasswordSafeException") {throw}

            if ($_.Exception.GetType().FullName -eq "System.Net.WebException" -and $_.Exception.Response.StatusCode -eq 404) {
                #404 not found
                $details= $DETAILS_REQUEST_02 -f $SystemID, $AccountID
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