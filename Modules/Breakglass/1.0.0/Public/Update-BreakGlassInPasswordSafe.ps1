<#
This function will synchronize or align information from PAM
with a KeePassXC database

#>


function Update-BreakglassInPasswordSafe {
    param (
        [Parameter(Mandatory=$true)][Object[]] $Accounts,
        [Parameter(Mandatory=$false)][string] $Password,

        [Parameter(Mandatory=$false)][switch] $Quiet= $false,
        [Parameter(Mandatory=$false)][switch] $WhatIf= $false
    )

    if ($WhatIf) {$quiet= $false}

    $requests= Get-BTRequest -Refresh

    #
    # loop through all accounts and fetch password for each.
    # it is required to have a request for fetching a password
    #
    foreach ($acc in $Accounts) {

        #
        # Update password and fetch the new password
        #
        $res= Update-BTManagedAccountPassword -AccountID $acc.AccountID -Password $Password


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
                    $reqID= New-BTRequest -AccountID $acc.ID -SystemID $acc.SystemId -Duration 15
                } else {
                    $reqID= $req.RequestID
                }

                $pwd= Get-BTManagedAccountPassword -RequestID $reqID
                $acc.accountPassword= $pwd
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
    }
}

# --- end-of-file ---