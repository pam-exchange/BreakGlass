<#
MIT License

Copyright (c) 2025 PAM-Exchange

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

#>
#--------------------------------------------------------------------------------------

$Script:cacheManagedSystemBase= New-Object System.Collections.ArrayList
$Script:cacheManagedSystemByID= New-Object System.Collections.HashTable		# Index into cache array

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
				$Script:cacheManagedSystemBase.Clear()
				$Script:cacheManagedSystemByID.Clear()

				#$res = PSafe-Get "ManagedSystems?limit=$(urlencode($Limit))&offset=$(urlencode($Offset))";
                $res = PSafe-Get "ManagedSystems";
				$res | %{
					$tmp= _Normalize-ManagedSystem($_)

					$key= $tmp.ID
					$idx= $Script:cacheManagedSystemBase.Add( $tmp ) 
					$Script:cacheManagedSystemByID.Add( $key, $idx ) | Out-Null		# External ID into array idx
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
				$res= $Script:cacheManagedSystemBase
					
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