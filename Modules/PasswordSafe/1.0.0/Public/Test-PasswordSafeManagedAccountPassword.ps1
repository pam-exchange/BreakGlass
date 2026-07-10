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
function Test-PasswordSafeManagedAccountPassword () 
{
    Param(
        [Parameter(Mandatory=$true)][int] $AccountID
    )
    
    process {
        try {
            $res= PSafe-Post "ManagedAccounts/$AccountID/Credentials/Test"
            return $res.Success
        }
        catch
        {
            if ($_.Exception.GetType().FullName -eq "PasswordSafeException") {throw}

            if ($_.Exception.GetType().FullName -eq "System.Net.WebException" -and $_.Exception.Response.StatusCode -eq 404) {
                if ($_.ErrorDetails.Message -match "Request has been released or is expired") {
                    $details= $DETAILS_MANAGEDACCOUNTPASSWORD_01
                    throw ( New-Object PasswordSafeException( $EXCEPTION_NOT_FOUND, $details ) )
                }
                throw ( New-Object PasswordSafeException( $EXCEPTION_NOT_FOUND ) )
            }
            throw
        }
    }
}

# --- end-of-file ---