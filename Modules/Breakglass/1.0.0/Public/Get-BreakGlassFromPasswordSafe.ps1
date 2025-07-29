<#
This function will lookup breakglass accounts in PAM (Password Safe), fetch the 
password and return a list of entries

#>
# ------------------------------------------------------------------------------------
function Get-BreakglassFromPasswordSafe {
    param (
        [Parameter(Mandatory=$false)][switch] $Quiet= $false,
        [Parameter(Mandatory=$false)][switch] $WhatIf= $false
    )

    if ($WhatIf) {$quiet= $false}

    $list= New-Object System.Collections.ArrayList

    #
    # Get all breakglass accounts
    # PAM smartrule will filter accounts for breakglass
    #
    $accounts= Get-BTManagedAccount

    #
    # Get all existing requests
    #
    $requests= Get-BTRequest -Refresh

    #
    # loop through all accounts and fetch password for each.
    # it is required to have a request for fetching a password
    #
    foreach ($acc in $accounts) {

        #
        # Platform is the type of account, e.g. Windows, Linux, AD, MSSQL, ...
        #
        $platformName= (Get-BTPlatform -PlatformID $acc.platformID).Name

        $cnt= 0
        do {
            #
            # Loop is required for the scenario that a request expired since it was requested
            # and tested when filtering by IDs and datetime.
            #
            # A rare scenario, but it may happen that the test was done (not expired) and it then
            # expires before the password is fetched using the now expired RequestID. 
            # If there is a time mismatch between calling system and PAM, the opposite scenario
            # that a new request is requested although a valid request still exist.
            # If so, an exception is thrown by the calling function. 
            # Wait a bit and try again. If the issue is different, do this at most 5 times,
            # then rethrow the exception.
            #

            try {
                # Find request by IDs and filter request already expired
                $now= Get-Date
                $req= $requests | Where-Object {($_.accountID -eq $acc.AccountID) -and ($now -lt [DateTime]$($_.ExpiresDate))}

                if (-not $req) {
                    $reqID= New-BTRequest -AccountID $acc.AccountID -SystemID $acc.SystemID -Duration 15
                } else {
                    $reqID= $req.RequestID
                }

                $pwd= Get-BTManagedAccountPassword -RequestID $reqID -useDSS:$acc.useDSS
                break
            } 
            catch {
                $cnt++
                if (-not $Quiet) {Write-Host "$($_.Exception.Message) - $($_.Exception.Details)" -ForegroundColor DarkGray}
                if ($cnt -gt 5) {
                    throw
                }
                Sleep -Milliseconds 500
            }
        } while ($true)

        $list.add( [PSCustomObject]@{server=$($acc.SystemName); accountType=$platformName; accountID=$($acc.AccountID); accountName=$($acc.AccountName); accountPassword=$pwd; verified=$($acc.Verified)} ) | Out-Null
    }

    return $list
}

# --- end-of-file ---