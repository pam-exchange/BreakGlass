$script:cachePlatformBase= New-Object System.Collections.ArrayList
$script:cachePlatformByID= New-Object System.Collections.HashTable	# Index into cache array

enum DSS_FLAG {
	Any
	True
	False
}



function Get-PwsPlatform () {

    Param(
		[Alias("PlatformID")]
        [parameter(Mandatory=$false)][int] $ID= -1,

        [Alias("PlatformName")]
        [parameter(Mandatory=$false)][string] $Name,
		[Parameter(Mandatory=$false)][DSS_FLAG] $DSSFlag= "Any",
		
        [Parameter(Mandatory=$false)][switch] $useRegex= $false,
        [Parameter(Mandatory=$false)][switch] $Single= $false,
        [Parameter(Mandatory=$false)][switch] $Refresh= $false,
        [Parameter(Mandatory=$false)][switch] $NoEmptySet= $false
    )
    
	process {
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
				if ($DSSFlag -ne "Any") { $res= $res | Where-Object {$_.DSSFlag -eq $DSSFlag} }
				if ($useRegex) {
					if ($name) { $res= $res | Where-Object {$_.Name -match $name} }
				}
				else {
					if ($name) { $res= $res | Where-Object {$_.Name -like $name} }
				}
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
                $details= $DETAILS_PLATFORM_01
                throw ( New-Object PasswordSafeException( $EXCEPTION_NOT_FOUND, $details ) )
            }

            throw
        }
    }
}

# --- end-of-file ---