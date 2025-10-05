function Test-OsQueryInstall {
	<#
	.SYNOPSIS
		Checks if osquery is installed on the system.
	.DESCRIPTION
		Tests for the presence of the osquery installation and returns version information if available.
	.PARAMETER Detailed
		If specified, provides detailed information about the osquery installation.
	.EXAMPLE
		Test-OsQueryInstall
		
		Checks if osquery is installed on the system.
	.EXAMPLE
		Test-OsQueryInstall -Detailed

		Checks if osquery is installed and returns detailed information about the installation.
	#>
	[CmdletBinding()]
	param(
		[parameter(Mandatory=$false)][switch]$Detailed
	)
	if ($IsLinux) {
		if (-not(Test-Path -Path "/opt/osquery/bin/osqueryd")) {
			Write-Verbose "osqueryd not found in /opt/osquery/bin/. Please ensure osquery is installed."
			return
		} else {
			if ($Detailed.IsPresent) {
				$osqueryPath = "/opt/osquery/bin/osqueryd"
				$osqueryVersion = & $osqueryPath --version
				return [PSCustomObject]@{
					Installed = $True
					Platform  = 'Linux'
					Path      = $osqueryPath
					Version   = $osqueryVersion
				}
			} else {
				$True
			}
		}
	} elseif ($IsWindows) {
		if (-not(Test-Path -Path "C:\Program Files\osquery\osqueryd.exe")) {
			Write-Verbose "osqueryd not found in C:\Program Files\osquery\. Please ensure osquery is installed."
			return
		} else {
			if ($Detailed.IsPresent) {
				$osqueryPath = "C:\Program Files\osquery\osqueryd.exe"
				$osqueryVersion = & $osqueryPath --version
				return [PSCustomObject]@{
					Installed = $True
					Platform  = 'Windows'
					Path      = $osqueryPath
					Version   = $osqueryVersion
				}
			} else {
				$True
			}
		}
	} elseif ($IsMacOS) {
		if (-not(Test-Path -Path "/opt/osquery/lib/osquery.app")) {
			Write-Verbose "osqueryd not found in /opt/osquery/lib/. Please ensure osquery is installed."
			return
		} else {
			if ($Detailed.IsPresent) {
				$osqueryPath = "/opt/osquery/lib/osquery.app"
				$osqueryVersion = & $osqueryPath --version
				return [PSCustomObject]@{
					Installed = $True
					Platform  = 'MacOS'
					Path      = $osqueryPath
					Version   = $osqueryVersion
				}
			} else {
				$True
			}
		}
	} else {
		Write-Verbose "Unsupported operating system."
		return
	}
}