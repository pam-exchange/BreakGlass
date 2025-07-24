$ScriptPath = Split-Path $MyInvocation.MyCommand.Path
$PSModule = $ExecutionContext.SessionState.Module
$PSModuleRoot = $PSModule.ModuleBase

#region Load Private Functions
Try {
    if (Test-Path "$ScriptPath\Private") {
        $PrivateFunctions = @(Get-ChildItem -Path "$ScriptPath\Private" -Filter *.ps1 -ErrorAction SilentlyContinue)
        foreach ($import in $PrivateFunctions) {
            try {
                . $import.FullName
            } catch {
                Write-Warning "Failed to import function $($import.FullName): $_"
            }
        }
    }
} Catch {
    Write-Warning "Failed to import private function: $_"
    Continue
}
#endregion Load Private Functions

#region Load Public Functions
Try {
    $NoExport= @()
    $PublicFunctions = @(Get-ChildItem -Path "$ScriptPath\public" -Filter *.ps1 -ErrorAction SilentlyContinue)
    $ToExport = $PublicFunctions | Where-Object { $_.BaseName -notin $NoExport } | Select-Object -ExpandProperty BaseName

    foreach ($import in $PublicFunctions) {
        try {
            . $import.FullName
        } catch {
            Write-Warning "Failed to import function $($import.FullName): $_"
        }
    }
    Export-ModuleMember -Function $ToExport
}
catch {
    Write-Warning "Failed to import public function: $_"
}
#endregion Load Public Functions
