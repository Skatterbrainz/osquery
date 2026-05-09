function Get-OsQueryProcesses {
	<#
	.SYNOPSIS
		Retrieves running process information from osquery.
	.DESCRIPTION
		Queries the 'processes' table to return process inventory including PID, name, path, and resource usage.
	.PARAMETER Name
		Filter results to processes matching this name (case-sensitive, exact match).
	.PARAMETER Limit
		Maximum number of records to return. Default is 0 (all).
	.PARAMETER ComputerName
		Remote computer to query. If not provided, queries locally.
	.EXAMPLE
		Get-OsQueryProcesses

		Returns all running processes.
	.EXAMPLE
		Get-OsQueryProcesses -Name "pwsh" -Limit 5

		Returns up to 5 processes named "pwsh".
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$false)][string]$Name,
		[parameter(Mandatory=$false)][int]$Limit = 0,
		[parameter(Mandatory=$false)][string]$ComputerName
	)
	$tablename = 'processes'
	if (-not [string]::IsNullOrEmpty($Name)) {
		$query = "SELECT * FROM $tablename WHERE name = '$Name';"
	} elseif ($Limit -gt 0) {
		$query = "SELECT * FROM $tablename LIMIT $Limit;"
	} else {
		$query = "SELECT * FROM $tablename;"
	}
	$invokeParams = @{ Query = $query }
	if (![string]::IsNullOrEmpty($ComputerName)) { $invokeParams.ComputerName = $ComputerName }
	Invoke-OsQueryTableQuery @invokeParams | Select-Object -Property *, @{Name = 'tablename'; Expression = { $tablename }}
}
