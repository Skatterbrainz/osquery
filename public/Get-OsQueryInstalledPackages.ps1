function Get-OsQueryInstalledPackages {
	<#
	.SYNOPSIS
		Retrieves installed package information from osquery.
	.DESCRIPTION
		Queries all available package tables (deb_packages, rpm_packages, flatpak_packages,
		chocolatey_packages, homebrew_packages, and python_packages) and
		returns unified results with the source table included as a column.
	.PARAMETER Limit
		Maximum number of records to return across all package tables.
		Default is 0 (all).
	.PARAMETER ComputerName
		Remote computer to query. If not provided, queries locally.
	.EXAMPLE
		Get-OsQueryInstalledPackages

		Returns installed packages from all available package tables.
	.EXAMPLE
		Get-OsQueryInstalledPackages -Limit 50

		Returns up to 50 combined package records across all package tables.
	.EXAMPLE
		Get-OsQueryInstalledPackages | Group-Object tablename

		Queries for counts of installed packages by package manager.

	.EXAMPLE
		Get-OsQueryInstalledPackages -ComputerName "RemotePC"

		Queries installed packages on the specified remote computer.
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$false)][int]$Limit = 0,
		[parameter(Mandatory=$false)][string]$ComputerName
	)
	$packageTables = @(
		'deb_packages',
		'rpm_packages',
		'flatpak_packages',
		'chocolatey_packages',
		'homebrew_packages',
		'python_packages'
	)

	$registryQuery = "SELECT name FROM osquery_registry WHERE registry = 'table' AND name IN ('$(($packageTables -join "','"))');"
	$invokeParams = @{ Query = $registryQuery }
	if (![string]::IsNullOrEmpty($ComputerName)) { $invokeParams.ComputerName = $ComputerName }
	$availableTables = @(
		Invoke-OsQueryTableQuery @invokeParams |
			ForEach-Object { $_.name } |
			Where-Object { -not [string]::IsNullOrEmpty($_) } |
			Sort-Object -Unique
	)

	$tablesToQuery = $packageTables | Where-Object { $_ -in $availableTables }
	$remaining = $Limit
	$results = foreach ($tablename in $tablesToQuery) {
		if ($Limit -gt 0 -and $remaining -le 0) { break }

		$limitClause = if ($Limit -gt 0) { " LIMIT $remaining" } else { '' }
		$query = "SELECT *, '$tablename' AS tablename FROM $tablename$limitClause;"
		$currentInvokeParams = @{ Query = $query }
		if (![string]::IsNullOrEmpty($ComputerName)) { $currentInvokeParams.ComputerName = $ComputerName }

		$tableResults = @(Invoke-OsQueryTableQuery @currentInvokeParams)
		if ($Limit -gt 0) { $remaining -= $tableResults.Count }
		$tableResults
	}

	$results
}
