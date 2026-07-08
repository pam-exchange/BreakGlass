function Write-Log {
    param (
        [Parameter(Mandatory=$true)][string]$Message,
        [Parameter(Mandatory=$false)][ValidateSet("Info", "Warning", "Error", "Debug")][string]$Level = "Info",
        [Parameter(Mandatory=$false)][ConsoleColor]$ForegroundColor
    )

    $stack = Get-PSCallStack
    $caller = $stack[1]
    $callerInfo = ""
    if ($null -ne $caller) {
        $fileName = Split-Path $caller.ScriptName -Leaf
        $callerInfo = "[$fileName:$($caller.ScriptLineNumber) $($caller.FunctionName)]"
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $callerInfo $Message"

    if (-not $ForegroundColor) {
        switch ($Level) {
            "Info"    { $ForegroundColor = "White" }
            "Warning" { $ForegroundColor = "Yellow" }
            "Error"   { $ForegroundColor = "Red" }
            "Debug"   { $ForegroundColor = "Gray" }
        }
    }

    Write-Host $logMessage -ForegroundColor $ForegroundColor
}

Export-ModuleMember -Function Write-Log
