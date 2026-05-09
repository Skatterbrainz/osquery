function Get-OsQueryLoggedInUsers {
	<#
	.SYNOPSIS
		Retrieves currently logged-in user session information from osquery.
	.DESCRIPTION
		Queries the 'logged_in_users' table to return active login sessions
		including user, type, host, and login time.
	.PARAMETER ComputerName
		Remote computer to query. If not provided, queries locally.
	.EXAMPLE
		Get-OsQueryLoggedInUsers

		Returns all active login sessions on the local machine.
	.EXAMPLE
		Get-OsQueryLoggedInUsers -ComputerName "server01"

		Returns active sessions on a remote computer.
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$false)][string]$ComputerName
	)
	$tablename = 'logged_in_users'
	$invokeParams = @{ Query = "SELECT * FROM $tablename;" }
	if (![string]::IsNullOrEmpty($ComputerName)) { $invokeParams.ComputerName = $ComputerName }
	Invoke-OsQueryTableQuery @invokeParams | Select-Object -Property *, @{Name = 'tablename'; Expression = { $tablename }}
}
