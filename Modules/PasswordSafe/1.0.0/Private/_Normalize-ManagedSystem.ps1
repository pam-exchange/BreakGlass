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