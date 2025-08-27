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

#
# Cache is defined in Get-PwsRequest
#
# $script:cacheRequestsBase= New-Object System.Collections.ArrayList
# $script:cacheRequestsByID= New-Object System.Collections.HashTable	# Index into cache array
#

enum CONFLICT {
    Error
    Reuse
    Renew
}

function New-PwsRequest () {

    Param(
        [parameter(Mandatory=$false)][int] $AccountID= -1,
        [parameter(Mandatory=$false)][string] $AccountName,
        [parameter(Mandatory=$false)][int] $SystemID= -1,
        [parameter(Mandatory=$false)][string] $SystemName,

        [parameter(Mandatory=$false)][int] $Duration= 1,
        [parameter(Mandatory=$false)][CONFLICT] $Conflict= "Error",
        [parameter(Mandatory=$false)][string] $Reason= "API CheckOut",
        [parameter(Mandatory=$false)][switch] $RotateOnCheckin= $false
    )
    
	process {
		try {

            if ($SystemName -and -not $SystemID -ge 0) {
                $sys= Get-PwsManagedSystem -Name $SystemName -Single
                $SystemID= $sys.Name
            }

            if ($AccountName -and -not $AccountID -ge 0) {
                $acc= Get-PwsManagedAccount -Name $AccountName -SystemID $SystemID
                $AccountID= $acc.ID
            }

            $body = @{
                "AccessType"             = "View"
                "SystemID"               = $SystemID
                "AccountID"              = $AccountID
                "DurationMinutes"        = $Duration
                "Reason"                 = $Reason
                "AccessPolicyScheduleID" = $null
                "RotateOnCheckin"        = $RotateOnCheckin
            }
            if ($Conflict -ne "Error") {
                $body.Add("ConflictOption", $Conflict)
            }

            try {

                $reqID = PSafe-Post "Requests" $body;
            
                <#
                TO-DO: Caching?
                #>


            }
            catch {
                Throw "Error: $_"
            }

            return $reqID
		}
        catch
        {
            if ($_.Exception.GetType().FullName -eq "PasswordSafeException") {throw}

            if ($_.Exception.GetType().FullName -eq "System.Net.WebException" -and $_.Exception.Response.StatusCode -eq 404) {
                #404 not found
                $details= $DETAILS_REQUEST_02 -f $SystemID, $AccountID
                throw ( New-Object PasswordSafeException( $EXCEPTION_NOT_FOUND, $details ) )
            }

            throw
        }
    }
}

# --- end-of-file ---