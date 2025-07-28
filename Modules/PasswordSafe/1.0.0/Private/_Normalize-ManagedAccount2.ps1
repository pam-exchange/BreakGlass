function _Normalize-ManagedAccount2 () {
    Param(
        $org
    )

    $tmp= $org

    $tmp | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value "ManagedAccount"

    $tmp | Add-Member -MemberType NoteProperty -Name 'ID' -Value $org.ManagedAccountID
    $tmp | Add-Member -MemberType NoteProperty -Name 'AccountID' -Value $org.ManagedAccountID
    $tmp | Add-Member -MemberType NoteProperty -Name 'Name' -Value $org.AccountName
    $tmp | Add-Member -MemberType NoteProperty -Name 'SystemID' -Value $org.ManagedSystemID
    $tmp | Add-Member -MemberType NoteProperty -Name 'SystemName' -Value $org.domainName

    $tmp.psobject.Properties.Remove('ManagedAccountID')
    #$tmp.psobject.Properties.Remove('AccountName')
    $tmp.psobject.Properties.Remove('ManagedSystemID')

    return $tmp
}

# --- end-of-file ---
