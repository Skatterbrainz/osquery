function Test-OsQueryInstall {
	<#
	.SYNOPSIS
		Checks if osquery is installed on the system.
	.DESCRIPTION
		Uses Get-Command to locate osqueryi in PATH and returns version information if available.
	.PARAMETER Detailed
		If specified, returns a detailed object with install path and version.
	.EXAMPLE
		Test-OsQueryInstall

		Returns $true if osqueryi is found in PATH, $false otherwise.
	.EXAMPLE
		Test-OsQueryInstall -Detailed

		Returns a PSCustomObject with Installed, Platform, Path, and Version properties.
	#>
	[CmdletBinding()]
	param(
		[parameter(Mandatory=$false)][switch]$Detailed
	)
	$platform = if ($IsLinux) { 'Linux' } elseif ($IsWindows) { 'Windows' } elseif ($IsMacOS) { 'MacOS' } else { 'Unknown' }
	$osqueryPath = Get-OsQueryBinaryPath

	if (-not $osqueryPath) {
		if ($Detailed.IsPresent) {
			return [PSCustomObject]@{
				Installed = $false
				Platform  = $platform
				Path      = $null
				Version   = $null
			}
		}
		return $false
	}

	if ($Detailed.IsPresent) {
		return [PSCustomObject]@{
			Installed = $true
			Platform  = $platform
			Path      = $osqueryPath
			Version   = (& $osqueryPath --version 2>&1)
		}
	}
	return $true
}
