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
