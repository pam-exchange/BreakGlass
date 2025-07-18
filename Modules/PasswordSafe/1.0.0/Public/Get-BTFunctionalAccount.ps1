$script:cacheFunctionalAccountBase= New-Object System.Collections.ArrayList
$script:cacheFunctionalAccountByID= New-Object System.Collections.HashTable		# Index into cache array

function Get-BTFunctionalAccount () 
{

    Param(
		[Alias("AccountID")]
        [Parameter(Mandatory=$false)][int] $ID= -1,
		
		[Alias("AccountName")]
        [Parameter(Mandatory=$false)][string] $Name,
		
        [Parameter(Mandatory=$false)][switch] $Single= $false,
        [Parameter(Mandatory=$false)][switch] $Refresh= $false,
        [Parameter(Mandatory=$false)][switch] $NoEmptySet= $false
    )
    
	process {
        #Write-PSFMessage -Level Debug "Start -- ID='$($ID)', AccountName='$($AccountName)', Single='$($Single)', NoEmptySet='$($NoEmptySet)'"

		try {
			#
			# Fetch and build cache
			#
			if ($Refresh -or -not $Script:cacheFunctionalAccountBase) {
				$script:cacheFunctionalAccountBase.Clear()
				$script:cacheFunctionalAccountByID.Clear()

				$res = PSafe-Get "FunctionalAccounts";
				$res | %{
					$tmp= _Normalize-FunctionalAccount($_)

					$key= $tmp.ID
					$idx= $script:cacheFunctionalAccountBase.Add( $tmp ) 
					$script:cacheFunctionalAccountByID.Add( $key, $idx ) | Out-Null		# External ID into array idx
				}
			}

			#
			# Apply filter
			#
            if ($ID -ge 0) {
				# By ID
				$idx= $Script:cacheFunctionalAccountByID[ [int]$ID ]		# External ID to array idx
				$res= $Script:cacheFunctionalAccountBase[ [int]$idx ]
            }
			else {
				$res= $script:cacheFunctionalAccountBase
				if ($Name) {
					# search by name
					if ($Name) {$res= $res | Where-Object {$_.Name -like $Name}}
				}
			}

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

            #Write-PSFMessage -Level Debug "Found $($res2.Count) functional accounts (filtered)"
            return $res
		}
        catch
        {
            if ($_.Exception.GetType().FullName -eq "PasswordSafeException") {throw}

            if ($_.Exception.GetType().FullName -eq "System.Net.WebException" -and $_.Exception.Response.StatusCode -eq 404) {
                #404 not found
                $details= $DETAILS_FUNCTIONALACCOUNT_01
                #Write-PSFMessage -Level Error "Message= '$EXCEPTION_NOT_FOUND', Details= '$($details)'"
                throw ( New-Object PasswordSafeException( $EXCEPTION_NOT_FOUND, $details ) )
            }
            #Write-PSFMessage -Level Error ("Exception - Type= $($_.Exception.GetType().FullName), Message= $($_.Exception.Message), Details= $($_.ErrorDetails)")
            throw
        }
    }
}

# --- end-of-file ---