function Show-OsQueryInstall {
	<#
	.SYNOPSIS
		Opens the osquery installation instructions in the default browser.
	.DESCRIPTION
		Launches the osquery installation documentation page for the current platform,
		or the general downloads page if the platform is not recognized.
	.PARAMETER Downloads
		If specified, opens the official downloads page instead of the documentation.
	.EXAMPLE
		Show-OsQueryInstall

		Opens the platform-specific installation documentation.
	.EXAMPLE
		Show-OsQueryInstall -Downloads

		Opens the official osquery downloads page.
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$false)][switch]$Downloads
	)
	if ($Downloads.IsPresent) {
		$url = 'https://osquery.io/downloads/official'
	} else {
		$url = if ($IsWindows) {
			'https://osquery.readthedocs.io/en/stable/installation/install-windows/'
		} elseif ($IsMacOS) {
			'https://osquery.readthedocs.io/en/stable/installation/install-macos/'
		} else {
			'https://osquery.readthedocs.io/en/stable/installation/install-linux/'
		}
	}
	Write-Verbose "Opening: $url"
	Start-Process $url
}
