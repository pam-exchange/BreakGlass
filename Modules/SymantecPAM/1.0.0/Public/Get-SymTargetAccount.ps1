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

$Script:cacheTargetAccountBase= New-Object System.Collections.ArrayList
$Script:cacheTargetAccountByID= New-Object System.Collections.HashTable		# Index into cache array

enum DETAILS {
    COMPACT
    FULL
}


#--------------------------------------------------------------------------------------
function Get-SymTargetAccount () 
{
    Param(
		[Alias("AccountID")]
        [Parameter(Mandatory=$false)][int] $ID= -1,
		
		[Alias("AccountName")]
        [Parameter(Mandatory=$false)][string] $Name,

        [Parameter(Mandatory=$false)][int] $SystemID= -1,			# Filter by ManagedSystem ID
        [Parameter(Mandatory=$false)][string] $SystemName,			# Filter by ManagedSystem Name
        

        [Parameter(Mandatory=$false)][DETAILS] $details= "COMPACT",

        [Parameter(Mandatory=$false)][switch] $useRegex= $false,
        [Parameter(Mandatory=$false)][switch] $Single= $false,
		[Parameter(Mandatory=$false)][switch] $Refresh= $false,
        [Parameter(Mandatory=$false)][switch] $NoEmptySet= $false
    )
    
	process {
		try {

            #
            # To-Do: Needs a complete rework allowing filtering by AccountName, etc...
            #

            if ($details -eq "COMPACT") {

                $res= Invoke-SymantecCLI -cmd "listTargetAccounts"

                $result= $res.'cr.result'.'c.cw.m.tacs'
                $res= $result | ForEach-Object {[PSCustomObject]@{TargetServerID=$_.'ts.id'; TargetServerName=$_.hn; TargetapplicationID=$_.'ta.id'; TargetapplicationName=$_.na; TargetAccountID=$_.'bm.id'; TargetAccountName=$_.un; Verified=([System.convert]::ToBoolean($_.pv))}}

            }
            else {

                $res= Invoke-SymantecCLI -cmd "searchTargetAccounts"

                foreach ($s in $res."cr.result".TargetAccount) {

                    $ta= Convert-XmlToPS -XML $s -filter "^(ID|deviceID|name|extensionType|policyID|targetServerID|Attribute\.(?!extensionType).*)$"

                    $idx= $Script:cacheTargetAccountBase.Add( $ta )
                    $Script:cacheTargetAccountByID.Add( [int]($ta.ID), [int]($idx) )
                }



                #
                # TO-DO: Detailed TargetAccount
                # Fetch TargetApplication and TargetServer
                [System.Collections.ArrayList]$res = @()
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
            throw
        }
    }
}

# --- end-of-file ---