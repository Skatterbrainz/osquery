function Get-OsQueryChromeExtensions {
    <#
    .SYNOPSIS
    Retrieves information about installed Chrome extensions on the system.

    .DESCRIPTION
    This function queries the chrome_extensions table using osquery to return details about all installed Chrome extensions.

    .EXAMPLE
    Get-OsQueryChromeExtensions
    #>
    [CmdletBinding()]
    param()

    $query = "SELECT * FROM chrome_extensions;"
    Write-Verbose "Executing query: $query"
    Invoke-OsQueryTableQuery -Query $query
}