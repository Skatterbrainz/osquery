function Get-OsQueryPackageSources {
    <#
    .SYNOPSIS
    Retrieves information about package sources on the system.

    .DESCRIPTION
    This function queries the apt_sources and yum_sources tables using osquery to return details about all package sources.

    .EXAMPLE
    Get-OsQueryPackageSources
    #>
    [CmdletBinding()]
    param()

    $query = "SELECT * FROM apt_sources;"
    Write-Verbose "Executing query: $query"
    $result = Invoke-OsQueryTableQuery -Query $query
    $query = "SELECT * FROM yum_sources;"
    Write-Verbose "Executing query: $query"
    $result += Invoke-OsQueryTableQuery -Query $query
    return $result
}