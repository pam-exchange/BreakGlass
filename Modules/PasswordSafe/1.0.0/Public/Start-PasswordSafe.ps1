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
function Start-PasswordSafe {
    param (
        [Parameter(Mandatory = $true)][string] $ApiDNS,
        [Parameter(Mandatory = $true)][string] $ApiWorkgroup,
        [Parameter(Mandatory = $true)][string] $ApiKey,
        [Parameter(Mandatory = $true)][string] $ApiUsername,
        [Parameter(Mandatory = $false)][string] $ApiPassword
    )
    process {
        $Script:apiWorkgroup = $ApiWorkgroup
        $Script:apiURL = "https://$ApiDNS/BeyondTrust/api/public/v3/"
        $Script:apiKey = $ApiKey
        $Script:apiUsername = $ApiUsername
        $Script:apiPassword = $ApiPassword

        $method = "POST"
        $uri = $Script:apiURL + "Auth/SignAppin"
        $headers = PSafe-BuildHeaders
        $Script:PSHeaders = $headers

        try {
            if ($Script:authCert -eq $null) {
                $result = Invoke-RestMethod -Uri $uri -Method $method -Headers $headers -SessionVariable Script:session
            }
            else {
                $result = Invoke-RestMethod -Uri $uri -Method $method -Headers $headers -SessionVariable Script:session -Certificate $Script:authCert
            }
            return $result
        }
		catch [System.Net.WebException]
		{
			#401 with WWW-Authenticate-2FA header expected for two-factor authentication challenge
			if($_.Exception.Response.StatusCode -eq 401 -and $_.Exception.Response.Headers.Contains("WWW-Authenticate-2FA") -eq $true)
			{
				$challengeMessage = $_.Exception.Response.Headers["WWW-Authenticate-2FA"];
				$challengeResponse = Read-Host $challengeMessage;
				PSafe-SignAppinChallenge $challengeResponse;
			}
            elseif ($_.Exception.Response.StatusCode -eq "Unauthorized") {
                $details = $DETAILS_EXCEPTION_NOT_AUTHORIZED_01 -f $ApiUsername
                throw (New-Object PasswordSafeException($EXCEPTION_NOT_AUTHORIZED, $details))
            }
			else {
				throw;
			}
		}
	}
}

# --- end-of-file ---