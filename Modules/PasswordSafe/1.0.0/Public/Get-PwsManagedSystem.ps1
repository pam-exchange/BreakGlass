$script:cacheManagedSystemBase= New-Object System.Collections.ArrayList
$script:cacheManagedSystemByID= New-Object System.Collections.HashTable		# Index into cache array

function Get-PwsManagedSystem () 
{
    Param(
        [Alias("SystemID")]
		[Parameter(Mandatory=$false)][int] $ID= -1,
		
        [Alias("SystemName")]
        [Parameter(Mandatory=$false)][string] $Name,
		
        [Parameter(Mandatory=$false)][int] $PlatformID= -1,
        [Parameter(Mandatory=$false)][string] $PlatformName,
		
        [Alias("DnsName")]
        [Parameter(Mandatory=$false)][string] $Hostname,
        [Parameter(Mandatory=$false)][string] $Description,
        [Parameter(Mandatory=$false)][string] $Workgroup,

        [Parameter(Mandatory=$false)][int] $AssetID= -1,
        [Parameter(Mandatory=$false)][string] $AssetName,
        
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
					
                if ($platformID -eq -1 -and $PlatformName) {
                    $platform= Get-PwsPlatform -Name $PlatformName -Single 
                    $platformID= $platform.ID
                }

				if ($AssetName -and $AssetID -eq -1) {
					# Find asset by name
					$asset= Get-PwsAsset -Name $AssetName -Single
					$AssetID= $asset.ID
				}

    			if ($AssetID -ge 0) {$res= $res | Where-Object {$_.AssetID -eq $AssetID}}
				if ($PlatformID -ge 0) {$res= $res | Where-Object {$_.PlatformID -eq $PlatformID}}

				if ($useRegex) {
					if ($Name) {$res= $res | Where-Object {$_.Name -match $Name}}
					if ($Hostname) {$res= $res | Where-Object {$_.DnsName -match $Hostname}}
					if ($Description) {$res= $res | Where-Object {$_.Description -match $Description}}
					if ($Workgroup) {$res= $res | Where-Object {$_ -match $Workgroup}}
				}
				else {
					if ($Name) {$res= $res | Where-Object {$_.Name -like $Name}}
					if ($Hostname) {$res= $res | Where-Object {$_.DnsName -like $Hostname}}
					if ($Description) {$res= $res | Where-Object {$_.Description -like $Description}}
					if ($Workgroup) {$res= $res | Where-Object {$_ -like $Workgroup}}
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