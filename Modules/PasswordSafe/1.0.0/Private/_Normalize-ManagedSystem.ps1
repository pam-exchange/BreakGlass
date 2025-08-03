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
function _Normalize-ManagedSystem () {
    Param(
        $org
    )

    $tmp= $org

    $tmp | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value "ManagedSystem" -Force
    $tmp | Add-Member -MemberType NoteProperty -Name 'ID' -Value $org.ManagedSystemID -Force
    $tmp | Add-Member -MemberType NoteProperty -Name 'Name' -Value $org.SystemName -Force

    if ($null -ne $org.DnsName) {
        $dns= $org.DnsName.toLower()
        #Write-PSFMessage -Level Debug "$($tmp | ConvertTo-Json )"
        #Write-PSFMessage -Level Debug "DnsName= $($tmp.DnsName)"
        #Write-PSFMessage -Level Debug "HostName= $($tmp.HostName)"
        $tmp.psobject.Properties.Remove('DnsName')
        $tmp | Add-Member -MemberType NoteProperty -Name 'DnsName' -Value $dns -Force
    }

    $tmp.psobject.Properties.Remove('ManagedSystemID')
    $tmp.psobject.Properties.Remove('SystemName')

    return $tmp
}

# --- end-of-file ---