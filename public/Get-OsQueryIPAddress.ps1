function Get-OsQueryIPAddress {
	<#
	.SYNOPSIS
	Retrieves IP address information from the osquery database.

	.DESCRIPTION
	This function queries the 'interface_addresses' table in the osquery database to retrieve IP address information.

	.PARAMETER Limit
	Specifies the maximum number of IP address records to return. Default is 0.

	.EXAMPLE
	Get-OsQueryIPAddress

	Retrieves all IP address records from the osquery database.

	.EXAMPLE
	Get-OsQueryIPAddress -Limit 25

	Retrieves up to 25 IP address records from the osquery database.

	#>

	[CmdletBinding()]
	param (
		[int]$Limit = 0
	)

	$tablename = "interface_addresses"

	if ($Limit -gt 0) {
		$query = "SELECT * FROM $tablename LIMIT $Limit;"
	} else {
		$query = "SELECT * FROM $tablename;"
	}
	Invoke-OsQueryTableQuery -Query $query | Select-Object -Property *, @{Name = "tablename"; Expression = { $tablename }}
}