function Get-OsQueryMounts {
    <#
    .SYNOPSIS
    Retrieves information about mounted filesystems on the system.

    .DESCRIPTION
    This function queries the mounts table using osquery to return details about all mounted filesystems.

    .EXAMPLE
    Get-OsQueryMounts

    Returns information about all mounted filesystems on the system.
    #>
    [CmdletBinding()]
    param()

    $query = "SELECT * FROM mounts;"
    Write-Verbose "Executing query: $query"
    Invoke-OsQueryTableQuery -Query $query
}