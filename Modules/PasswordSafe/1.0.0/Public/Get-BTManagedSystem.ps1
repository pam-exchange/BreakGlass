$script:cacheManagedSystemBase= New-Object System.Collections.ArrayList
$script:cacheManagedSystemByID= New-Object System.Collections.HashTable		# Index into cache array

function Get-BTManagedSystem () 
{
    Param(
        [Alias("SystemID")]
		[Parameter(Mandatory=$false)][int] $ID= -1,
		
        [Alias("SystemName")]
        [Parameter(Mandatory=$false)][string] $Name,
		
        [Alias("DnsName")]
        [Parameter(Mandatory=$false)][string] $Hostname,
        [Parameter(Mandatory=$false)][string] $Description,
        [Parameter(Mandatory=$false)][string] $Workgroup,

        #[Parameter(Mandatory=$false)][int] $PlatformID,
        #[Parameter(Mandatory=$false)][string] $PlatformName,
		
        [Parameter(Mandatory=$false)][int] $AssetID= -1,
        [Parameter(Mandatory=$false)][string] $AssetName,
        
        #[Parameter(Mandatory=$false)][int] $Limit= 100000,
        #[Parameter(Mandatory=$false)][int] $Offset= 0,
		
        [Parameter(Mandatory=$false)][switch] $Single= $false,
        [Parameter(Mandatory=$false)][switch] $Refresh= $false,
        [Parameter(Mandatory=$false)][switch] $NoEmptySet= $false
    )
    
	process {
		#Write-PSFMessage -Level Debug "Start -- ID='$($ID)', Name='$($Name)', Hostname='$($Hostname)', Description='$($Description)', Workgroup='$($Workgroup)', AssetID='$($AssetID)', AssetName='$($AssetName)', Limit='$($Limit)', Offset='$($Offset)', Single='$($Single)', Refresh='$($Refresh)', NoEmptySet='$($NoEmptySet)'"

		try {
			#
			# Fetch and build cache
			#
			if ($Refresh -or -not $Script:cacheManagedSystemBase) {
				$script:cacheManagedSystemBase.Clear()
				$script:cacheManagedSystemByID.Clear()

				#$res = PSafe-Get "ManagedSystems?limit=$(urlencode($Limit))&offset=$(urlencode($Offset))";
                $res = PSafe-Get "ManagedSystems";
				$res | %{
					$tmp= _Normalize-ManagedSystem($_)

					$key= $tmp.ID
					$idx= $script:cacheManagedSystemBase.Add( $tmp ) 
					$script:cacheManagedSystemByID.Add( $key, $idx ) | Out-Null		# External ID into array idx
				}
			}

			#
			# Apply filter
			#
            if ($ID -ge 0) {
				$idx= $Script:cacheManagedSystemByID[ [int]$ID ]		# External ID to array idx
				$res= $Script:cacheManagedSystemBase[ [int]$idx ]
            }
			else {
				$res= $script:cacheManagedSystemBase
				if ($Name -or $Hostname -or $Description -or $Workgroup -or $AssetName -or $AssetID) {
					# Apply filter
					
					if ($AssetName -and $AssetID -lt 0) {
						# Find asset by name
						$asset= Get-BTAsset -Name $AssetName -Single
						$AssetID= $asset.ID
					}

					if ($AssetID -ge 0) {
						$res= $res | Where-Object { $_.AssetID -eq $AssetID }
					}
					else {
						# search cache by name, hostname, description and workgroup
						if ($Name) {$res= $res | Where-Object {$_.Name -like $Name}}
						if ($Hostname) {$res= $res | Where-Object {$_.DnsName -like $Hostname}}
						if ($Description) {$res= $res | Where-Object {$_.Description -like $Description}}
						if ($Workgroup) {$res= $res | Where-Object {$_ -like $Workgroup}}
					}
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

            #Write-PSFMessage -Level Debug "Found $($res2.Count) ManagedSystem (filtered)"
            return $res
		}
        catch
        {
            if ($_.Exception.GetType().FullName -eq "PasswordSafeException") {throw}

            if ($_.Exception.GetType().FullName -eq "System.Net.WebException" -and $_.Exception.Response.StatusCode -eq 404) {
                # 404 - NotFound
                if ($_.ErrorDetails -imatch "Managed System not found") {
                    $details= $DETAILS_MANAGEDSYSTEM_01
                    #Write-PSFMessage -Level Error "Message= '$EXCEPTION_NOT_FOUND', Details= '$($details)'"
                    throw ( New-Object PasswordSafeException( $EXCEPTION_NOT_FOUND, $details ) )
                }
            }
            #Write-PSFMessage -Level Error ("Exception - Type= $($_.Exception.GetType().FullName), Message= $($_.Exception.Message), Details= $($_.ErrorDetails)")
            #Write-PSFMessage -Level Debug -Message "ScriptStackTrace:`n$($_.ScriptStackTrace)"
            throw
        }
    }
}

# --- end-of-file ---