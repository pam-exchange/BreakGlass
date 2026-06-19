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

$Script:cacheManagedAccountBase= New-Object System.Collections.ArrayList
$Script:cacheManagedAccountByID= New-Object System.Collections.HashTable		# Index into cache array

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
				$Script:cacheManagedAccountBase.Clear()
				$Script:cacheManagedAccountByID.Clear()

                #
                # Get smartrule for api_Breakglass user. Should only be one rule
                #
                $rules= PSafe-Get "Smartrules"

				#
				# Find accounts visible through smartrule filter
				#
                foreach ($rule in $rules) {
                    $res= PSafe-Get "smartrules/$($rule.SmartRuleID)/managedaccounts"
				    $res | %{
					    $tmp= _Normalize-ManagedAccount2($_)

                        $system= Get-PwsManagedSystem -ID $tmp.SystemID

                        if (-not $tmp.SystemName) {
                            $tmp.SystemName= $system.name
                        }
                        $tmp.PlatformName= (Get-PwsPlatform -ID $system.PlatformID -Single -NoEmptySet).Name

					    $key= $tmp.ID
					    $idx= $Script:cacheManagedAccountBase.Add( $tmp ) 
					    $Script:cacheManagedAccountByID.Add( $key, $idx ) | Out-Null		# External ID into array idx

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
				$res= $Script:cacheManagedAccountBase
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