$script:cacheManagedAccountBase= New-Object System.Collections.ArrayList
$script:cacheManagedAccountByID= New-Object System.Collections.HashTable		# Index into cache array

#--------------------------------------------------------------------------------------
function Get-PwsManagedAccount () 
{
    Param(
		[Alias("ID")]
        [Parameter(Mandatory=$false)][int] $AccountID= -1,
		
		[Alias("Name")]
        [Parameter(Mandatory=$false)][string] $AccountName,

        [Parameter(Mandatory=$false)][int] $SystemID= -1,			# Filter by ManagedSystem ID
        [Parameter(Mandatory=$false)][string] $SystemName,			# Filter by ManagedSystem Name
        
        #[Parameter(Mandatory=$false)][string] $Description,         # Filter by description
        #[Parameter(Mandatory=$false)][string] $Workgroup,           # Filter by description

        #[Parameter(Mandatory=$false)][int] $Limit= 100000,
        #[Parameter(Mandatory=$false)][int] $Offset= 0,
        
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
			if ($Refresh -or -not $Script:cacheManagedAccountBase) {
				$script:cacheManagedAccountBase.Clear()
				$script:cacheManagedAccountByID.Clear()
				
                #
                # Directory accounts are found using "ManagedSystem/{ID}/ManagedAccounts"
                #
                $directory= Get-PwsManagedSystem -PlatformName "Active Directory"
                foreach ($d in $directory) {
                    $res= PSafe-Get "ManagedSystems/$($d.ID)/ManagedAccounts"
				    $res | %{
					    $tmp= _Normalize-ManagedAccount2($_)

					    $key= $tmp.ID
					    $idx= $script:cacheManagedAccountBase.Add( $tmp ) 
					    $script:cacheManagedAccountByID.Add( $key, $idx ) | Out-Null		# External ID into array idx
				    }
                }

                #
                # Other accounts are found using "ManagedAccounts"
                #
				$res = PSafe-Get "ManagedAccounts";
				$res | %{
					$tmp= _Normalize-ManagedAccount($_)

					$key= $tmp.ID
					$idx= $script:cacheManagedAccountBase.Add( $tmp ) 
					$script:cacheManagedAccountByID.Add( $key, $idx ) | Out-Null		# External ID into array idx
				}

                #
                # Need to query all system where Breakglass account
                # exist and where the platform supports DSS keys
                #
                $dssPlatformID= (Get-PwsPlatform -DSSFlag True).ID
                $msIDs= ($res | Where-Object {$_.PlatformID -in $dssPlatformID} | Select-Object SystemID -Unique).SystemID
                foreach ($msID in $msIDs) {
                    $res= PSafe-Get "ManagedSystems/$msID/ManagedAccounts";
                    $res | Where-Object {$_.DSSAutoManagementFlag} | %{
                        #
                        # Not normalized and AccountID is named ManagedAccountID
                        #
                        $idx= $script:cacheManagedAccountByID[ $_.ManagedAccountId ]
                        $script:cacheManagedAccountBase[ $idx ].useDSS= $true
                    }
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
				if ($SystemID -ge 0) {$res= $res | Where-Object {$_.SystemId -eq $SystemID}}
				
				if ($useRegex) {
					if ($Name) {$res= $res | Where-Object {$_.Name -match $Name}}
					if ($SystemName) {$res= $res | Where-Object {$_.SystemName -match $SystemName}}
					#if ($Description) {$res= $res | Where-Object {$_.Description -match $Description}}
					#if ($Workgroup) {$res= $res | Where-Object {$_.Workgroup -match $Workgroup}}
				}
				else {
					if ($Name) {$res= $res | Where-Object {$_.Name -like $Name}}
					if ($SystemName) {$res= $res | Where-Object {$_.SystemName -like $SystemName}}
					#if ($Description) {$res= $res | Where-Object {$_.Description -like $Description}}
					#if ($Workgroup) {$res= $res | Where-Object {$_.Workgroup -like $Workgroup}}
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
                # 404 - NotFound
                if ($_.ErrorDetails -imatch "Managed Account not found") {
                    $details= $DETAILS_MANAGEDACCOUNT_01
                    throw ( New-Object PasswordSafeException( $EXCEPTION_NOT_FOUND, $details ) )
                }
                if ($_.ErrorDetails -imatch "Managed System not found") {
                    $details= $DETAILS_MANAGEDSYSTEM_01
                    throw ( New-Object PasswordSafeException( $EXCEPTION_NOT_FOUND, $details ) )
                }
            }

            throw
        }
    }
}

# --- end-of-file ---