function Get-OsQueryGroups {
	<#
	.SYNOPSIS
		Retrieves local group information from osquery.
	.DESCRIPTION
		Queries the 'groups' table to return local group accounts.
	.PARAMETER Limit
		Maximum number of records to return. Default is 0 (all).
	.PARAMETER ComputerName
		Remote computer to query. If not provided, queries locally.
	.EXAMPLE
		Get-OsQueryGroups

		Returns all local groups.
	.EXAMPLE
		Get-OsQueryGroups -Limit 10 -ComputerName "server01"

		Returns up to 10 groups from a remote computer.
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$false)][int]$Limit = 0,
		[parameter(Mandatory=$false)][string]$ComputerName
	)
	$tablename = 'groups'
	$query = if ($Limit -gt 0) { "SELECT * FROM $tablename LIMIT $Limit;" } else { "SELECT * FROM $tablename;" }
	$invokeParams = @{ Query = $query }
	if (![string]::IsNullOrEmpty($ComputerName)) { $invokeParams.ComputerName = $ComputerName }
	Invoke-OsQueryTableQuery @invokeParams | Select-Object -Property *, @{Name = 'tablename'; Expression = { $tablename }}
}
