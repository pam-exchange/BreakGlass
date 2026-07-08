function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string] $Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Info", "Warning", "Error", "Debug","Success")]
        [string] $Level = "Info",
        
        [Parameter(Mandatory=$false)]
        [ConsoleColor] $ForegroundColor,
        
        [Parameter(Mandatory = $false)]
        [switch] $NoNewline = $false
    )

    $stack = Get-PSCallStack
    $caller = $stack[1]
    $callerInfo = ""
    if ($null -ne $caller) {
        $fileName = Split-Path $caller.ScriptName -Leaf
        $callerInfo = "   [$fileName"+":"+"$($caller.ScriptLineNumber)]"
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    #$logMessage = "[$timestamp] [$Level] $Message $callerInfo"
    $logMessage = $Message
    $logMessage = "[$Level] $Message $callerInfo"

    if (-not $ForegroundColor) {
        switch ($Level) {
            "Info"    { $ForegroundColor = "Green" }
            "Warning" { $ForegroundColor = "Yellow" }
            "Error"   { $ForegroundColor = "Red" }
            "Debug"   { $ForegroundColor = "Gray" }
            "Success" { $ForegroundColor = "White" }
            default   { $ForegroundColor = "White" }
        }
    }

    Write-Host $logMessage -ForegroundColor $ForegroundColor -NoNewline:$NoNewLine
}

Export-ModuleMember -Function Write-Log
