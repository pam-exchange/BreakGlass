Set-Variable EXCEPTION_INVALID_PARAMETER -Option Constant -Value "Invalid parameters"
Set-Variable EXCEPTION_NOT_FOUND -Option Constant -Value "Not found"
#Set-Variable EXCEPTION_DUPLICATE -Option Constant -Value "Duplicate" 
#Set-Variable EXCEPTION_DEPENDENCY -Option Constant -Value "Dependency"
Set-Variable EXCEPTION_NOT_AUTHORIZED -Option Constant -Value "Not authorized"
#Set-Variable EXCEPTION_FORBIDDEN -Option Constant -Value "Forbidden"
Set-Variable EXCEPTION_NOT_SINGLE -Option Constant -Value "Not single"

Set-Variable DETAILS_EXCEPTION_NOT_SINGLE_01 -Option Constant -Value "Multiple elements found when using parameter '-Single'"
Set-Variable DETAILS_EXCEPTION_NOT_FOUND_01 -Option Constant -Value "Nothing found when using parameter '-NoEmptySet'"
Set-Variable DETAILS_EXCEPTION_NOT_AUTHORIZED_01 -Option Constant -Value "API user '{0}' is not authorized"


Set-Variable DETAILS_FUNCTIONALACCOUNT_01 -Option Constant -Value "Functional account not found"
Set-Variable DETAILS_MANAGEDACCOUNT_01 -Option Constant -Value "Managed Account not found"
Set-Variable DETAILS_MANAGEDSYSTEM_01 -Option Constant -Value "Managed System not found"
Set-Variable DETAILS_PLATFORM_01 -Option Constant -Value "Platform is not found"
Set-Variable DETAILS_REQUEST_01 -Option Constant -Value "RequestID is not found"
Set-Variable DETAILS_REQUEST_02 -Option Constant -Value "Cannot find system/account for new request (systemID={0}, accountID=(1))"



class PasswordSafeException : Exception {
    [string] $Details

    PasswordSafeException($Message) : base($Message) {
        $this.Details= ""
    }
    PasswordSafeException($Message, $Details) : base($Message) {
        $this.Details= $Details
    }
}

# --- end-of-file ---