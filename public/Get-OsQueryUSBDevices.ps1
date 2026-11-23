function Get-OsQueryUSBDevices {
    <#
    .SYNOPSIS
    Retrieves information about USB devices on the system.

    .DESCRIPTION
    This function queries the usb_devices table using osquery to return details about all connected USB devices.

    .EXAMPLE
    Get-OsQueryUSBDevices
    #>
    [CmdletBinding()]
    param()
    $query = "SELECT * FROM usb_devices;"
    Write-Verbose "Executing query: $query"
    Invoke-OsQueryTableQuery -Query $query
}