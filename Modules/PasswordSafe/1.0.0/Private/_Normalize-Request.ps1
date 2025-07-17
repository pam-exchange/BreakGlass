function _Normalize-Request () {
    Param(
        $org
    )

    $tmp= $org

    $tmp | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value "Request"

    $tmp | Add-Member -MemberType NoteProperty -Name 'ID' -Value $org.RequestID
    #$tmp.psobject.Properties.Remove('RequestID')

    return $tmp
}

# --- end-of-file ---