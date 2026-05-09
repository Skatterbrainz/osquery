function Get-OsQueryInstalledPackages {
	<#
	.SYNOPSIS
		Retrieves installed package information from osquery.
	.DESCRIPTION
		Queries the appropriate platform package table (deb_packages, rpm_packages,
		chocolatey_packages, or homebrew_packages). Auto-detects the package manager
		based on the current platform unless overridden with -PackageManager.
	.PARAMETER PackageManager
		Package manager to query. If not specified, auto-detects based on platform:
		Linux -> deb, Windows -> chocolatey, macOS -> homebrew.
	.PARAMETER Limit
		Maximum number of records to return. Default is 0 (all).
	.PARAMETER ComputerName
		Remote computer to query. If not provided, queries locally.
	.EXAMPLE
		Get-OsQueryInstalledPackages

		Returns installed packages using the auto-detected package manager.
	.EXAMPLE
		Get-OsQueryInstalledPackages -PackageManager rpm -Limit 50

		Returns up to 50 packages from the rpm_packages table.
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$false)]
		[ValidateSet('deb', 'rpm', 'chocolatey', 'homebrew', 'python')]
		[string]$PackageManager,
		[parameter(Mandatory=$false)][int]$Limit = 0,
		[parameter(Mandatory=$false)][string]$ComputerName
	)
	if ([string]::IsNullOrEmpty($PackageManager)) {
		$PackageManager = if ($IsWindows) { 'chocolatey' } elseif ($IsMacOS) { 'homebrew' } else { 'deb' }
	}
	$tablename = switch ($PackageManager) {
		'deb'        { 'deb_packages' }
		'rpm'        { 'rpm_packages' }
		'chocolatey' { 'chocolatey_packages' }
		'homebrew'   { 'homebrew_packages' }
		'python'     { 'python_packages' }
	}
	$query = if ($Limit -gt 0) { "SELECT * FROM $tablename LIMIT $Limit;" } else { "SELECT * FROM $tablename;" }
	$invokeParams = @{ Query = $query }
	if (![string]::IsNullOrEmpty($ComputerName)) { $invokeParams.ComputerName = $ComputerName }
	Invoke-OsQueryTableQuery @invokeParams | Select-Object -Property *, @{Name = 'tablename'; Expression = { $tablename }}
}
