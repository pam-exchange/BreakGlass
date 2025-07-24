#--------------------------------------------------------------------------------------
function Start-SymantecPAM (

    [Parameter(Mandatory = $true)] [string]$cliDNS,
    [Parameter(Mandatory = $true)] [string]$cliUsername,
    [Parameter(Mandatory = $true)] [string]$cliPassword,
    [Parameter(Mandatory = $false)] [int]$cliPageSize= 100000
)
{
	#Write-PSFMessage -Level Debug ("Start-BeyondTrust: start")

    $script:cliURL= "https://$($cliDNS)/cspm/servlet/adminCLI"
    $script:cliUsername= $cliUsername
    $script:cliPassword= $cliPassword
    $script:cliPageSize= $cliPageSize
}

# --- end-of-file ---