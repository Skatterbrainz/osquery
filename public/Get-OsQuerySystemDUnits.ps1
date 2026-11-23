function Get-OsQuerySystemDUnits {
    <#
    .SYNOPSIS
    Retrieves information about systemd units on the system.

    .DESCRIPTION
    This function queries the systemd_units table using osquery to return details about all systemd units.

    .EXAMPLE
    Get-OsQuerySystemDUnits
    #>
    [CmdletBinding()]
    param()

    $query = "SELECT * FROM systemd_units;"
    Write-Verbose "Executing query: $query"
    Invoke-OsQueryTableQuery -Query $query
}