function Get-OsQueryFirewall {
	<#
	.SYNOPSIS
		Retrieves firewall rule information from osquery.
	.DESCRIPTION
		Queries the appropriate platform firewall table:
		'iptables' on Linux, 'windows_firewall_rules' on Windows, 'alf' on macOS.
	.PARAMETER ComputerName
		Remote computer to query. If not provided, queries locally.
	.EXAMPLE
		Get-OsQueryFirewall

		Returns firewall rules for the current platform.
	.EXAMPLE
		Get-OsQueryFirewall -ComputerName "server01"

		Returns firewall rules from a remote computer.
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$false)][string]$ComputerName
	)
	$tablename = if ($IsWindows) { 'windows_firewall_rules' } elseif ($IsMacOS) { 'alf' } else { 'iptables' }
	$invokeParams = @{ Query = "SELECT * FROM $tablename;" }
	if (![string]::IsNullOrEmpty($ComputerName)) { $invokeParams.ComputerName = $ComputerName }
	Invoke-OsQueryTableQuery @invokeParams | Select-Object -Property *, @{Name = 'tablename'; Expression = { $tablename }}
}
