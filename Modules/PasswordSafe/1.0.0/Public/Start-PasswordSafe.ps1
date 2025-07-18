#--------------------------------------------------------------------------------------
function Start-PasswordSafe (

    [Parameter(Mandatory = $true)] [string]$apiDNS,
    [Parameter(Mandatory = $true)] [string]$apiWorkgroup,
    [Parameter(Mandatory = $true)] [string]$apiKey,
    [Parameter(Mandatory = $true)] [string]$apiUsername,
    [Parameter(Mandatory = $false)] [string]$apiPassword
)
{
	#Write-PSFMessage -Level Debug ("Start-BeyondTrust: start")

    $script:apiWorkgroup= $apiWorkgroup
    $script:apiURL= "https://$apiDNS/BeyondTrust/api/public/v3/"
    $script:apiKey= $apiKey
    $script:apiUsername= $apiUsername
    $script:apiPassword= $apiPassword

    $method = "POST";
    $uri= $Script:apiURL+"Auth/SignAppin"
    $headers = PSafe-BuildHeaders;
    $script:PSHeaders= $headers

    #Write-PSFMessage -Level Debug "uri= $uri"
    #Write-PSFMessage -Level Debug "headers.Authorization= $($headers.Authorization)"

    try
    {
        if ($Script:authCert -eq $null) {
            $result = Invoke-RestMethod -Uri $uri -Method $method -Headers $headers -SessionVariable Script:session
        }
        else {
            $result = Invoke-RestMethod -Uri $uri -Method $method -Headers $headers -SessionVariable Script:session -Certificate $Script:authCert
        }
        return $result;
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
        else
        {
            throw;
        }
    }
}

# --- end-of-file ---