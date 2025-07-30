#--------------------------------------------------------------------------------------
#Client Certificate Parameters:
#Type of certificate. Possible values:
#None
#BICertificate
#SmartCardLogon
$clientCertificateType = "None";

#--------------------------------------------------------------------------------------
#Builds a full URI for the given API
function PSafe-BuildUri([string]$api)
{
    return "{0}{1}" -f $Script:apiUrl, $api;
}

#--------------------------------------------------------------------------------------
#Builds and returns the headers for the request
function PSafe-BuildHeaders()
{
    #Build the Authorization header
    if ( $Script:apiPassword -eq $null ) { 
		return @{ Authorization="PS-Auth key=${Script:apiKey}; runas=${Script:apiUsername};"; }; 
	}
    else { 
		return @{ Authorization="PS-Auth key=${Script:apiKey}; runas=${Script:apiUsername}; pwd=[${Script:apiPassword}];"; }; 
	}
}

#--------------------------------------------------------------------------------------
# Calls the SignAppin API with an Authentication challenge
# Note: Should only be called after an initial attempt at Auth/SignAppin since it uses the existing Web Session
function PSafe-SignAppinChallenge($challengeResponse)
{
	#Write-PSFMessage -Level Debug ("start")

    $method = "POST";
    $uri= "$($script:apiUrl)Auth/SignAppin"
    $headers = @{ Authorization="PS-Auth key=${Script:ApiToken}; runas=${Script:Username};"; }

    # add challenge to the Auth header
    $headers["Authorization"] = "$($headers["Authorization"]) challenge=$($challengeResponse);"; 

    if ($Script:authCert -eq $null) {
        $result = Invoke-RestMethod -Uri $uri -Method $method -Headers $headers -WebSession $Script:session
    }
    else {
        $result = Invoke-RestMethod -Uri $uri -Method $method -Headers $headers -WebSession $Script:session -Certificate $Script:authCert
    }
	return $result
}

#--------------------------------------------------------------------------------------
# Calls the given API
function PSafe-RestMethod([string]$method, [string]$api, $body)
{
    $uri= "$($script:apiUrl)$api"
    
#    $local:attempt= 1
#    while ($true) {
        try {
            $res= Invoke-RestMethod -Uri $uri -Method $method -WebSession $Script:session -Headers $script:PSheaders -Body $body
            return $res
        }
        catch {
#            if ($local:attempt -le 5) {
#                $local:attempt+= 1
#                Start-Sleep -Milliseconds 250
#                continue
#            }
            throw
        }
#    }
}

#--------------------------------------------------------------------------------------
# Calls the given API with a custom Content Type
function PSafe-RestMethod-v2([string]$method, [string]$api, $body, $contentType)
{
    $uri= "$($script:apiUrl)$api"

    $local:attempt= 1
    while ($true) {
        try {
            $res= Invoke-RestMethod -Uri $uri -Method $method -WebSession $Script:session -ContentType $contentType -Headers $script:PSheaders -Body $body
            return $res
        }
        catch {
            if ($local:attempt -le 5) {
                #Write-PSFMessage -Level Debug "PSSafe-RestMethod: attempt= $($local:attempt), uri= $uri, Exception= $_"
                $local:attempt+= 1
                Start-Sleep -Milliseconds 250
                continue
            }
            throw
        }
    }
}

#--------------------------------------------------------------------------------------
# Calls a POST API
function PSafe-Post([string]$api, $body)
{
    #PSafe-RestMethod -method "POST" -api $api -body (ConvertTo-Json $body) -contentType "application/json"
    PSafe-RestMethod "POST" $api $body;
}

#--------------------------------------------------------------------------------------
# Calls a POST API v2
function PSafe-Post-v2([string]$api, $body)
{
    PSafe-RestMethod-v2 -method "POST" -api $api -body (ConvertTo-Json $body) -contentType "application/json;charset=utf-8"
}

#--------------------------------------------------------------------------------------
# Calls a GET API
function PSafe-Get([string]$api, $body)
{
    PSafe-RestMethod "GET" $api $body;
}

#--------------------------------------------------------------------------------------
# Calls a DELETE API
function PSafe-Delete([string]$api)
{
    PSafe-RestMethod "DELETE" $api;
}

#--------------------------------------------------------------------------------------
# Calls a PUT API
function PSafe-Put([string]$api, $body)
{
    PSafe-RestMethod2 "PUT" $api (ConvertTo-Json $body) "application/json"
}

#--------------------------------------------------------------------------------------
# Calls a PUT API v2
function PSafe-Put-v2([string]$api, $body)
{
    PSafe-RestMethod2 -method "PUT" -api $api -body (ConvertTo-Json $body) -contentType "application/json;charset=utf-8"
}

#--------------------------------------------------------------------------------------
# Certificate Functions
#--------------------------------------------------------------------------------------
# Find a client certificate
function PSafe-FindCertificate([string]$runAsUser)
{
    #Determine what type of cert to use
    switch($clientCertificateType)
    {
        #Beyond Insight certificate
        "BICertificate"
        { 
            $cert = PSafe-FindBICertificate $upn;
            return $cert;
        }

        #Smart Cards or equivalent
        "SmartCardLogon"
        { 
            # Assume UPN
            $upn = $runAsUser;

            # Parse SAM if needed
            if ($runAsUser.Contains("\"))
            {
                $idx = $runAsUser.IndexOf("\");
                $domain = $runAsUser.Substring(0, $idx);
                $user = $runAsUser.Substring($idx + 1);
                $upn = "{0}@{1}" -f $user, $domain;
            }

            # Find the client cert for a specific UPN
            $cert = PSafe-FindCertificateForUPN $upn;
            return $cert;
        }
            
        default { return $null; }
    }
}

#--------------------------------------------------------------------------------------
#Find the BeyondInsight signed client certificate
function PSafe-FindBICertificate()
{
    $certStore = "LocalMachine"; # Alternative: CurrentUser
    $subFieldName = "CN";
    $issuedTo = "eEyeEmsClient";

    $cert = PSafe-FindClientCertificates $certStore | Where-Object { $_.Subject -eq "${subFieldName}=${issuedTo}" };
    $cert;
}

#--------------------------------------------------------------------------------------
#Finds a client certificate for a User Principal Name, i.e. Smart Card Logon for AD account jdoe@doe-main
function PSafe-FindCertificateForUPN([string]$upnName)
{
    $certStore = "CurrentUser"; # Alternative: LocalMachine
    $nameType = "UpnName";

    $cert = PSafe-FindClientCertificates $certStore | Where-Object  {$_.GetNameInfo("${nameType}", $false) -eq $upnName };
    $cert;
}

#--------------------------------------------------------------------------------------
#Finds all client certificates in the given certificate store
function PSafe-FindClientCertificates([string]$certStore)
{
    $certs = Get-ChildItem -Path "cert:\${certStore}\My" -EKU "Client Authentication";
    retrn $certs;
}


#--------------------------------------------------------------------------------------
function uriencode( [string]$var ) 
{
    return [uri]::EscapeUriString($var)
}

#--------------------------------------------------------------------------------------
function urlencode( [string]$var ) 
{
    return [System.Web.HTTPUtility]::UrlEncode($var)
}

# --- end-of-file ---