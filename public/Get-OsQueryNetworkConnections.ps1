function Get-OsQueryNetworkConnections {
	<#
	.SYNOPSIS
		Retrieves network connection information from osquery.
	.DESCRIPTION
		Queries 'process_open_sockets' for all active connections, or 'listening_ports'
		when the -Listening switch is specified.
	.PARAMETER Listening
		If specified, queries the 'listening_ports' table instead of 'process_open_sockets'.
	.PARAMETER Limit
		Maximum number of records to return. Default is 0 (all).
	.PARAMETER ComputerName
		Remote computer to query. If not provided, queries locally.
	.EXAMPLE
		Get-OsQueryNetworkConnections

		Returns all open sockets across running processes.
	.EXAMPLE
		Get-OsQueryNetworkConnections -Listening

		Returns only ports in a listening state.
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$false)][switch]$Listening,
		[parameter(Mandatory=$false)][int]$Limit = 0,
		[parameter(Mandatory=$false)][string]$ComputerName
	)
	$tablename = if ($Listening.IsPresent) { 'listening_ports' } else { 'process_open_sockets' }
	$query = if ($Limit -gt 0) { "SELECT * FROM $tablename LIMIT $Limit;" } else { "SELECT * FROM $tablename;" }
	$invokeParams = @{ Query = $query }
	if (![string]::IsNullOrEmpty($ComputerName)) { $invokeParams.ComputerName = $ComputerName }
	Invoke-OsQueryTableQuery @invokeParams | Select-Object -Property *, @{Name = 'tablename'; Expression = { $tablename }}
}
