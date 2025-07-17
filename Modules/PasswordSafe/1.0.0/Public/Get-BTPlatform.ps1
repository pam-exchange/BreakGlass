$script:cachePlatformBase= New-Object System.Collections.ArrayList
$script:cachePlatformByID= New-Object System.Collections.HashTable	# Index into cache array

function Get-BTPlatform () {

    Param(
		[Alias("PlatformID")]
        [parameter(Mandatory=$false)][int] $ID= -1,

        [Alias("PlatformName")]
        [parameter(Mandatory=$false)][string] $Name,
		
        [Parameter(Mandatory=$false)][switch] $Single= $false,
        [Parameter(Mandatory=$false)][switch] $Refresh= $false,
        [Parameter(Mandatory=$false)][switch] $NoEmptySet= $false
    )
    
	process {
        #Write-PSFMessage -Level Debug "Start -- ID='$($ID)', Name='$($Name)', Single='$($Single)', Refresh='$($Refresh)', NoEmptySet='$($NoEmptySet)'"

		try {

			#
			# Fetch and build cache
			#
			if ($refresh -or -not $Script:cachePlatformBase) {
				$script:cachePlatformBase.Clear()
				$script:cachePlatformByID.Clear()

				# Write-PSFMessage -Level Debug "fetch multiple"
				$res = PSafe-Get "Platforms";
				$res | %{
					$tmp= _Normalize-Platform($_)

					$key= $tmp.ID
					$idx= $script:cachePlatformBase.Add( $tmp ) 
					$script:cachePlatformByID.Add( $key, $idx ) | Out-Null	# External ID into array idx
				}
			}
			
			#
			# Apply filter
			#
            if ($ID -ge 0) 
            {
				$idx= $Script:cachePlatformByID[ [int]$ID ]		# External ID to array idx
				$res= $Script:cachePlatformBase[ [int]$idx ]
            }
			else {
				$res= $Script:cachePlatformBase
				if ($name) {
					$res= $res | Where-Object {$_.Name -like $name}
				}
			}
			
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
                $details= $DETAILS_PLATFORM_01
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