function Test-ElevatedPrivilege {
	<#
	.SYNOPSIS
		Returns $true if the current session has elevated privileges.
	.DESCRIPTION
		Checks for root on Linux/macOS via 'id -u', and Administrator role on Windows
		via WindowsPrincipal. Used internally before service management operations.
	#>
	[CmdletBinding()]
	[OutputType([bool])]
	param()
	if ($IsWindows) {
		([System.Security.Principal.WindowsPrincipal]::new(
			[System.Security.Principal.WindowsIdentity]::GetCurrent()
		)).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
	} else {
		(& id -u 2>$null).Trim() -eq '0'
	}
}
