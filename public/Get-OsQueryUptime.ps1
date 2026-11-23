function Get-OsQueryUptime {
    <#
    .SYNOPSIS
        Retrieves system uptime from osquery.
    .DESCRIPTION
        Queries the uptime table to get the current system uptime.
    .EXAMPLE
        Get-OsQueryUptime

        Returns the current system uptime in Days, Hours, Minutes, Seconds and Total_Seconds.
    #>
    [CmdletBinding()]
    param()
    $query = "SELECT * FROM uptime;"
    Invoke-OsQueryTableQuery -Query $query
}