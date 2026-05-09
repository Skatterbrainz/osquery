function Get-OsQueryServices {
	<#
	.SYNOPSIS
		Retrieves service and startup item information from osquery.
	.DESCRIPTION
		Queries 'services' on Windows or 'startup_items' on Linux/macOS.
	.PARAMETER Limit
		Maximum number of records to return. Default is 0 (all).
	.PARAMETER ComputerName
		Remote computer to query. If not provided, queries locally.
	.EXAMPLE
		Get-OsQueryServices

		Returns services (Windows) or startup items (Linux/macOS).
	.EXAMPLE
		Get-OsQueryServices -Limit 25 -ComputerName "server01"

		Returns up to 25 service records from a remote computer.
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$false)][int]$Limit = 0,
		[parameter(Mandatory=$false)][string]$ComputerName
	)
	$tablename = if ($IsWindows) { 'services' } else { 'startup_items' }
	$query = if ($Limit -gt 0) { "SELECT * FROM $tablename LIMIT $Limit;" } else { "SELECT * FROM $tablename;" }
	$invokeParams = @{ Query = $query }
	if (![string]::IsNullOrEmpty($ComputerName)) { $invokeParams.ComputerName = $ComputerName }
	Invoke-OsQueryTableQuery @invokeParams | Select-Object -Property *, @{Name = 'tablename'; Expression = { $tablename }}
}
