$script:cacheManagedAccountBase= New-Object System.Collections.ArrayList
$script:cacheManagedAccountByID= New-Object System.Collections.HashTable		# Index into cache array

#--------------------------------------------------------------------------------------
function Get-BTManagedAccount () 
{
    Param(
		[Alias("AccountID")]
        [Parameter(Mandatory=$false)][int] $ID= -1,
		
		[Alias("AccountName")]
        [Parameter(Mandatory=$false)][string] $Name,

        [Parameter(Mandatory=$false)][int] $SystemID= -1,			# Filter by ManagedSystem ID
        [Parameter(Mandatory=$false)][string] $SystemName,			# Filter by ManagedSystem Name
        
        #[Parameter(Mandatory=$false)][string] $Description,         # Filter by description
        #[Parameter(Mandatory=$false)][string] $Workgroup,           # Filter by description

        #[Parameter(Mandatory=$false)][int] $Limit= 100000,
        #[Parameter(Mandatory=$false)][int] $Offset= 0,
        [Parameter(Mandatory=$false)][switch] $Single= $false,
		[Parameter(Mandatory=$false)][switch] $Refresh= $false,
        [Parameter(Mandatory=$false)][switch] $NoEmptySet= $false
    )
    
	process {
        #Write-PSFMessage -Level Debug "Start -- ID='$($ID)', Name='$($Name)', ManagedSystemID='$($ManagedSystemID)', ManagedSystemName='$($ManagedSystemName)', Description='$($Description)', Single='$($Single)', Refresh='$($Refresh)', NoEmptySet='$($NoEmptySet)'"

		try {
			#
			# Fetch and build cache
			#
			if ($Refresh -or -not $Script:cacheManagedAccountBase) {
				$script:cacheManagedAccountBase.Clear()
				$script:cacheManagedAccountByID.Clear()
				
				$res = PSafe-Get "ManagedAccounts";
				$res | %{
					$tmp= _Normalize-ManagedAccount($_)

					$key= $tmp.ID
					$idx= $script:cacheManagedAccountBase.Add( $tmp ) 
					$script:cacheManagedAccountByID.Add( $key, $idx ) | Out-Null		# External ID into array idx
				}
			}

			#
			# Apply filter
			#
            if ($ID -ge 0) {
				# By ID
				$idx= $Script:cacheManagedAccountByID[ [int]$ID ]		# External ID to array idx
				$res= $Script:cacheManagedAccountBase[ [int]$idx ]
            }
			else {
				$res= $script:cacheManagedAccountBase
				if ($Name -or $ManagedSystemID -or $ManagedSystemName -or $Description) {
					#if (-not $Name) {$Name= "*")
					#if (-not $ManagedSystemName) {$ManagedSystemName= "*")
					#if (-not $Description) {$Description= "*"}
					#if (-not $Workgroup) {$Workgroup= "*"}
					# $res= $script:cacheManagedSystemBase | Where-Object {($_.name -like $Name) -and ($_.SystemName -like $ManagedSystemName) -and ($_.Description -like $Description) -and ($_.Workgroup -like $Workgroup)}

					# search cache by name, hostname, description and workgroup
					if ($Name) {$res= $res | Where-Object {$_.Name -like $Name}}
					if ($SystemID -ge 0) {$res= $res | Where-Object {$_.ManagedSystemId -eq $SystemID}}
					if ($SystemName) {$res= $res | Where-Object {$_.ManagedSystemName -like $SystemName}}
					#if ($Description) {$res= $res | Where-Object {$_.Description -like $Description}}
					#if ($Workgroup) {$res= $res | Where-Object {$_.Workgroup -like $Workgroup}}
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

            #Write-PSFMessage -Level Debug "Found $($res2.Count) ManagedAccount (filtered)"
            return $res
		}
        catch
        {
            if ($_.Exception.GetType().FullName -eq "PasswordSafeException") {throw}

            if ($_.Exception.GetType().FullName -eq "System.Net.WebException" -and $_.Exception.Response.StatusCode -eq 404) {
                # 404 - NotFound
                if ($_.ErrorDetails -imatch "Managed Account not found") {
                    $details= $DETAILS_MANAGEDACCOUNT_01
                    #Write-PSFMessage -Level Error "Message= '$EXCEPTION_NOT_FOUND', Details= '$($details)'"
                    throw ( New-Object PasswordSafeException( $EXCEPTION_NOT_FOUND, $details ) )
                }
                if ($_.ErrorDetails -imatch "Managed System not found") {
                    $details= $DETAILS_MANAGEDSYSTEM_01
                    #Write-PSFMessage -Level Error "Message= '$EXCEPTION_NOT_FOUND', Details= '$($details)'"
                    throw ( New-Object PasswordSafeException( $EXCEPTION_NOT_FOUND, $details ) )
                }
            }
            #Write-PSFMessage -Level Error ("Exception - Type= $($_.Exception.GetType().FullName), Message= $($_.Exception.Message), Details= $($_.ErrorDetails)")
            #Write-PSFMessage -Level Debug ($_)
            #Write-PSFMessage -Level Debug "ScriptStackTrace:`n$($_.ScriptStackTrace)"
            throw
        }
    }
}

# --- end-of-file ---