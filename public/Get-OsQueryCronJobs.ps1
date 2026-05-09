function Get-OsQueryCronJobs {
	<#
	.SYNOPSIS
		Retrieves crontab scheduled job information from osquery.
	.DESCRIPTION
		Queries the 'crontab' table on Linux and macOS. Not supported on Windows.
	.PARAMETER ComputerName
		Remote computer to query. If not provided, queries locally.
	.EXAMPLE
		Get-OsQueryCronJobs

		Returns all crontab entries on the local machine.
	.EXAMPLE
		Get-OsQueryCronJobs -ComputerName "server01"

		Returns crontab entries from a remote Linux/macOS computer.
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$false)][string]$ComputerName
	)
	if ($IsWindows -and [string]::IsNullOrEmpty($ComputerName)) {
		Write-Warning "The 'crontab' table is not available on Windows."
		return
	}
	$tablename = 'crontab'
	$invokeParams = @{ Query = "SELECT * FROM $tablename;" }
	if (![string]::IsNullOrEmpty($ComputerName)) { $invokeParams.ComputerName = $ComputerName }
	Invoke-OsQueryTableQuery @invokeParams | Select-Object -Property *, @{Name = 'tablename'; Expression = { $tablename }}
}
