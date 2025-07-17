function _Normalize-Platform () {
    Param(
        $org
    )

    $tmp= $org

    $tmp | Add-Member -MemberType NoteProperty -Name 'ObjectType' -Value "Platform"

    $tmp | Add-Member -MemberType NoteProperty -Name 'ID' -Value $org.PlatformID
    $tmp.psobject.Properties.Remove('PlatformID')

    return $tmp
}

# --- end-of-file ---