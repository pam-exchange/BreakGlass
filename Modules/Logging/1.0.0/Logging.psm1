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

function Write-Log {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string] $Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Debug", "Success")]
        [string] $Level = "Info",

        [Parameter(Mandatory = $false)]
        [switch] $Quiet,

        [Parameter(Mandatory = $false)]
        [switch] $NoNewline
    )

    if ($Quiet -and $Level -notin @("Error", "Warning")) {
        return
    }

    $color = switch ($Level) {
        "Info"    { "Gray" }
        "Warning" { "Yellow" }
        "Error"   { "Red" }
        "Debug"   { "DarkGray" }
        "Success" { "Green" }
        default   { "White" }
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    # Future enhancement: output to file
    # $logEntry = "[$timestamp] [$Level] $Message"

    if ($NoNewline) {
        Write-Host $Message -ForegroundColor $color -NoNewline
    }
    else {
        Write-Host $Message -ForegroundColor $color
    }
}

Export-ModuleMember -Function Write-Log
