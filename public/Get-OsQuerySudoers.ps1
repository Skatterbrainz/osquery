function Get-OsQuerySudoers {
	<#
	.SYNOPSIS
		Retrieves sudoers configuration from osquery.
	.DESCRIPTION
		Queries the 'sudoers' table on Linux and macOS. Not supported on Windows.
	.PARAMETER ComputerName
		Remote computer to query. If not provided, queries locally.
	.EXAMPLE
		Get-OsQuerySudoers

		Returns the parsed sudoers configuration.
	.EXAMPLE
		Get-OsQuerySudoers -ComputerName "server01"

		Returns sudoers configuration from a remote Linux/macOS computer.
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$false)][string]$ComputerName
	)
	if ($IsWindows -and [string]::IsNullOrEmpty($ComputerName)) {
		Write-Warning "The 'sudoers' table is not available on Windows."
		return
	}
	if (($IsLinux -or $IsMacOS) -and [string]::IsNullOrEmpty($ComputerName)) {
		$uid = & id -u 2>$null
		if ($uid -ne '0') {
			Write-Warning "The 'sudoers' table requires elevated privileges. Re-run with sudo or as root."
			return
		}
	}
	$tablename = 'sudoers'
	$invokeParams = @{ Query = "SELECT * FROM $tablename;" }
	if (![string]::IsNullOrEmpty($ComputerName)) { $invokeParams.ComputerName = $ComputerName }
	Invoke-OsQueryTableQuery @invokeParams | Select-Object -Property *, @{Name = 'tablename'; Expression = { $tablename }}
}
