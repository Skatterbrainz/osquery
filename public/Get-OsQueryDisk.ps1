function Get-OsQueryDisk {
	<#
	.SYNOPSIS
		Retrieves disk and mount information from osquery.
	.DESCRIPTION
		Queries 'mounts' on Linux/macOS or 'disk_info' on Windows.
	.PARAMETER ComputerName
		Remote computer to query. If not provided, queries locally.
	.EXAMPLE
		Get-OsQueryDisk

		Returns mount points (Linux/macOS) or disk info (Windows).
	.EXAMPLE
		Get-OsQueryDisk -ComputerName "server01"

		Returns disk information from a remote computer.
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$false)][string]$ComputerName
	)
	$tablename = if ($IsWindows) { 'disk_info' } else { 'mounts' }
	$invokeParams = @{ Query = "SELECT * FROM $tablename;" }
	if (![string]::IsNullOrEmpty($ComputerName)) { $invokeParams.ComputerName = $ComputerName }
	Invoke-OsQueryTableQuery @invokeParams | Select-Object -Property *, @{Name = 'tablename'; Expression = { $tablename }}
}
