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

$script:cacheFunctionalAccountBase= New-Object System.Collections.ArrayList
$script:cacheFunctionalAccountByID= New-Object System.Collections.HashTable		# Index into cache array

function Get-PwsFunctionalAccount () 
{

    Param(
		[Alias("AccountID")]
        [Parameter(Mandatory=$false)][int] $ID= -1,
		
		[Alias("AccountName")]
        [Parameter(Mandatory=$false)][string] $Name,

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
				if ($useRegex) {
					if ($Name) {$res= $res | Where-Object {$_.Name -match $Name}}
				}
				else {
					if ($Name) {$res= $res | Where-Object {$_.Name -like $Name}}
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
                $details= $DETAILS_FUNCTIONALACCOUNT_01
                throw ( New-Object PasswordSafeException( $EXCEPTION_NOT_FOUND, $details ) )
            }

            throw
        }
    }
}

# --- end-of-file ---