Add-Type @"
using System.Net;
using System.Security.Cryptography.X509Certificates;
public class TrustAllCertsPolicy : ICertificatePolicy {
    public bool CheckValidationResult(
        ServicePoint srvPoint, X509Certificate certificate,
        WebRequest request, int certificateProblem) {
        return true;
    }
}
"@
[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

#--------------------------------------------------------------------------------------
function Invoke-SymantecCLI () {

    Param(
        [Parameter(Mandatory=$true)][string] $Cmd,
        [Parameter(Mandatory=$false)][Hashtable] $Params= @{}
    )

    $url= "$($script:cliUrl)`?cmdName=$cmd"
    $url+= "&adminUserID=$($script:cliUsername)"
    $url+= "&adminPassword=$($script:clipassword)"
    $url+= "&Page.Size=$($Script:cliPageSize)"
    
    $paramsStr= ($params.GetEnumerator() | ForEach-Object { "$($_.Key)=$($_.Value)" }) -join "&"
    if ($paramsStr) {$url+= "&"+$paramsStr}

    try {
        $res= Invoke-RestMethod -Uri $url -Method Get

        $statusCode= $($res.DocumentElement.statusCode)
        if ($statusCode -eq 400) {
            return ([xml]($res.DocumentElement.content.'#cdata-section')).CommandResult
        }

        if ($statudCode -eq 401) {
            $details= DETAILS_EXCEPTION_NOT_AUTHORIZED_01 -f $($script:apiUsername)
            throw (New-Object PasswordSafeException($EXCEPTION_NOT_AUTHORIZED, $details))
        }
        else {
            $details= $res.DocumentElement.statusMessage
            throw (New-Object PasswordSafeException($EXCEPTION_INVALID_PARAMETER, $details))
        }

    }
    catch {
        Write-Host $_.Exception
        # Invalid Hostname: $_.Exception.Message -eq "Unable to connect to the remote server"
        # URL valid: The remote server returned an error: (404) Not Found.

        if ($_.Exception.GetType().FullName -eq "SymantecPamException") {throw}

        if ($_.Exception.GetType().FullName -eq "System.Net.WebException") {
            $details= $_.Exception.Message
            throw ( New-Object SymantecPamException( $EXCEPTION_NOT_FOUND, $details ) )
        }

        # something else happened
        throw
    }
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