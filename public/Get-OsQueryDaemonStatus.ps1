function Get-OsQueryDaemonStatus {
	<#
	.SYNOPSIS
		Returns the current status of the osqueryd daemon.
	.DESCRIPTION
		On Linux, queries systemctl for active state, enabled state, and PID.
		On macOS, queries launchctl for the service entry.
		On Windows, queries the osqueryd Windows service via Get-Service and CIM.
	.EXAMPLE
		Get-OsQueryDaemonStatus

		Returns a status object for the osqueryd daemon on the current platform.
	.EXAMPLE
		Get-OsQueryDaemonStatus | Select-Object Status, Enabled, PID

		Returns just the status fields.
	#>
	[CmdletBinding()]
	[Alias('Get-OsQueryServiceStatus')]
	param()

	try {
		if ($IsLinux) {
			$activeState  = ([string](& systemctl is-active  osqueryd 2>$null)).Trim()
			$enabledState = ([string](& systemctl is-enabled osqueryd 2>$null)).Trim()
			$mainPid      = ([string](& systemctl show osqueryd --property=MainPID --value 2>$null)).Trim()
			[PSCustomObject]@{
				Name      = 'osqueryd'
				Platform  = 'Linux'
				Status    = $activeState
				Enabled   = $enabledState -eq 'enabled'
				PID       = if ($mainPid -and $mainPid -ne '0') { [int]$mainPid } else { $null }
			}
		} elseif ($IsMacOS) {
			# 'launchctl list' outputs tab-separated: PID, Status, Label
			$entry = & launchctl list 2>$null | Where-Object { $_ -match 'osqueryd' }
			if ($entry) {
				$parts = ($entry -split '\t')
				$pid   = if ($parts[0] -ne '-') { [int]$parts[0] } else { $null }
				[PSCustomObject]@{
					Name     = 'com.facebook.osqueryd'
					Platform = 'MacOS'
					Status   = if ($pid) { 'active' } else { 'inactive' }
					Enabled  = $true
					PID      = $pid
				}
			} else {
				[PSCustomObject]@{
					Name     = 'com.facebook.osqueryd'
					Platform = 'MacOS'
					Status   = 'not loaded'
					Enabled  = $false
					PID      = $null
				}
			}
		} elseif ($IsWindows) {
			$svc = Get-Service -Name osqueryd -ErrorAction SilentlyContinue
			if ($svc) {
				$cim = Get-CimInstance -ClassName Win32_Service -Filter "Name='osqueryd'" -ErrorAction SilentlyContinue
				[PSCustomObject]@{
					Name     = $svc.Name
					Platform = 'Windows'
					Status   = $svc.Status.ToString()
					Enabled  = $svc.StartType -ne 'Disabled'
					PID      = if ($cim.ProcessId -and $cim.ProcessId -ne 0) { $cim.ProcessId } else { $null }
				}
			} else {
				Write-Warning "osqueryd service was not found. Ensure osquery is installed."
				[PSCustomObject]@{
					Name     = 'osqueryd'
					Platform = 'Windows'
					Status   = 'not found'
					Enabled  = $false
					PID      = $null
				}
			}
		} else {
			Write-Warning "Unsupported platform."
		}
	} catch {
		Write-Error "Failed to get osqueryd status: $($_.Exception.Message)"
	}
}
