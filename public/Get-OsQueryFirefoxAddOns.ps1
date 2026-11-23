function Get-OsQueryFirefoxAddOns {
    <#
    .SYNOPSIS
    Retrieves information about installed Firefox add-ons on the system.

    .DESCRIPTION
    This function queries the firefox_addons table using osquery to return details about all installed Firefox add-ons.

    .EXAMPLE
    Get-OsQueryFirefoxAddOns
    #>
    [CmdletBinding()]
    param()

    $query = "SELECT * FROM firefox_addons;"
    Write-Verbose "Executing query: $query"
    Invoke-OsQueryTableQuery -Query $query
}