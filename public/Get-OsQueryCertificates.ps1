function Get-OsQueryCertificates {
	<#
	.SYNOPSIS
		Retrieves installed certificate information from osquery.
	.DESCRIPTION
		Queries the 'certificates' table to return installed certificate details
		including subject, issuer, and expiration.
	.PARAMETER Limit
		Maximum number of records to return. Default is 0 (all).
	.PARAMETER ComputerName
		Remote computer to query. If not provided, queries locally.
	.EXAMPLE
		Get-OsQueryCertificates

		Returns all installed certificates.
	.EXAMPLE
		Get-OsQueryCertificates -Limit 20 -ComputerName "server01"

		Returns up to 20 certificates from a remote computer.
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$false)][int]$Limit = 0,
		[parameter(Mandatory=$false)][string]$ComputerName
	)
	$tablename = 'certificates'
	$query = if ($Limit -gt 0) { "SELECT * FROM $tablename LIMIT $Limit;" } else { "SELECT * FROM $tablename;" }
	$invokeParams = @{ Query = $query }
	if (![string]::IsNullOrEmpty($ComputerName)) { $invokeParams.ComputerName = $ComputerName }
	Invoke-OsQueryTableQuery @invokeParams | Select-Object -Property *, @{Name = 'tablename'; Expression = { $tablename }}
}
