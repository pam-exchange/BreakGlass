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

        $statusCode= [int]$($res.DocumentElement.statusCode)
        if ($statusCode -eq 400) {
            return ([xml]($res.DocumentElement.content.'#cdata-section')).CommandResult
        }

        if ($statusCode -eq 401 -or $statusCode -eq 22) {
            $details= $DETAILS_EXCEPTION_NOT_AUTHORIZED_01 -f $($script:cliUsername)
            throw (New-Object SymantecPamException($EXCEPTION_NOT_AUTHORIZED, $details))
        }
        elseif ($statusCode -eq 5753 -or $statusCode -eq 15212) {
            # 5753 - PAM-CM-3432: Cannot connect to a domain controller on the specified domain
            # 15212 - PAM-CM-1341: Failed to establish a communications channel to the remote host.
            $details= $res.DocumentElement.statusMessage
            throw (New-Object SymantecPamException($EXCEPTION_PASSWORD_UPDATE, $details))
        }
        else {
            $details= $res.DocumentElement.statusMessage
            throw (New-Object SymantecPamException($EXCEPTION_INVALID_PARAMETER, $details))
        }

    }
    catch {
        #Write-Host $_.Exception
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