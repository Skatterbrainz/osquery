function Get-OsQueryBinaryPath {
	<#
	.SYNOPSIS
		Resolves the path to the osqueryi binary.
	.DESCRIPTION
		Uses Get-Command to locate osqueryi in the system PATH.
		Returns the full path string, or $null if not found.
	.EXAMPLE
		Get-OsQueryBinaryPath
	#>
	[CmdletBinding()]
	[OutputType([string])]
	param()
	(Get-Command -Name "osqueryi" -ErrorAction SilentlyContinue)?.Source
}
