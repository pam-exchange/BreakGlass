function Escape-Name () {
    Param(
        [string]$org
    )
    return $org
    #return $org -replace '[&\<>^\|]', '_'
    #return $org -replace '[&\\<>^\|]', '^$&'
}
