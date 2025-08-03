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