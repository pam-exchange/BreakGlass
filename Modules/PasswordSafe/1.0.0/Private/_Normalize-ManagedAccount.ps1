function _Normalize-ManagedAccount () {
    Param(
        $org
    )

    $tmp= $org

    $tmp | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value "ManagedAccount"

    $tmp | Add-Member -MemberType NoteProperty -Name 'ID' -Value $org.AccountID
    $tmp | Add-Member -MemberType NoteProperty -Name 'Name' -Value $org.AccountName
    $tmp | Add-Member -MemberType NoteProperty -Name 'useDSS' -Value $false
    #$tmp.psobject.Properties.Remove('AccountID')
    #$tmp.psobject.Properties.Remove('AccountName')

    return $tmp
}

# --- end-of-file ---
