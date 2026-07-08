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
Set-Variable EXCEPTION_GENERIC_ERROR -Option Constant -Value "Generic error"
Set-Variable EXCEPTION_INVALID_PARAMETER -Option Constant -Value "Invalid parameters"
Set-Variable EXCEPTION_INVALID_FORMAT -Option Constant -Value "Invalid format"
Set-Variable EXCEPTION_NOT_FOUND -Option Constant -Value "Not found"
Set-Variable EXCEPTION_DUPLICATE -Option Constant -Value "Already exists"
Set-Variable EXCEPTION_DEPENDENCY -Option Constant -Value "Dependency exists"
Set-Variable EXCEPTION_NOT_AUTHORIZED -Option Constant -Value "Not authorized"
Set-Variable EXCEPTION_FORBIDDEN -Option Constant -Value "Forbidden"
Set-Variable EXCEPTION_INITIALIZE -Option Constant -Value "Not Initialized"


class KeePassXCException : Exception {
    [string] $Details

    KeePassXCException($Message) : base($Message) {
        $this.Details= ""
    }
    KeePassXCException($Message, $Details) : base($Message) {
        $this.Details= $Details
    }
}

# --- end-of-file ---
