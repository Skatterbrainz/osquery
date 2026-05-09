function Disable-OsQueryDaemon {
	<#
	.SYNOPSIS
		Stops and disables the osqueryd daemon.
	.DESCRIPTION
		On Linux, uses systemctl to stop and disable osqueryd.
		On macOS, unloads the LaunchDaemon plist via launchctl.
		On Windows, stops the service and sets startup type to Disabled.
		Requires elevated privileges (root/Administrator).
	.EXAMPLE
		Disable-OsQueryDaemon

		Stops and disables the osqueryd daemon.
	.EXAMPLE
		Disable-OsQueryDaemon -WhatIf

		Shows what would happen without making any changes.
	#>
	[CmdletBinding(SupportsShouldProcess)]
	[Alias('Disable-OsQueryService')]
	param()

	if (-not (Test-ElevatedPrivilege)) {
		Write-Error "Disabling the osqueryd daemon requires elevated privileges. Re-run as root or Administrator."
		return
	}

	$changed = $false
	try {
		if ($IsLinux) {
			if ($PSCmdlet.ShouldProcess('osqueryd', 'Stop and disable via systemctl')) {
				Write-Verbose "Stopping osqueryd via systemctl..."
				$stopOut    = & systemctl stop    osqueryd 2>&1
				$disableOut = & systemctl disable osqueryd 2>&1
				if ($LASTEXITCODE -ne 0) { throw ($disableOut -join ' ') }
				if ($stopOut)    { Write-Verbose ($stopOut    -join ' ') }
				if ($disableOut) { Write-Verbose ($disableOut -join ' ') }
				$changed = $true
			}
		} elseif ($IsMacOS) {
			$plist = '/Library/LaunchDaemons/com.facebook.osqueryd.plist'
			if (-not (Test-Path $plist)) {
				throw "LaunchDaemon plist not found at '$plist'."
			}
			if ($PSCmdlet.ShouldProcess('com.facebook.osqueryd', 'Unload via launchctl')) {
				Write-Verbose "Unloading osqueryd via launchctl..."
				$out = & launchctl unload -w $plist 2>&1
				if ($LASTEXITCODE -ne 0) { throw ($out -join ' ') }
				$changed = $true
			}
		} elseif ($IsWindows) {
			if ($PSCmdlet.ShouldProcess('osqueryd', 'Stop service and set StartupType to Disabled')) {
				Write-Verbose "Stopping and disabling osqueryd service..."
				Stop-Service   -Name osqueryd -Force -ErrorAction Stop
				Set-Service    -Name osqueryd -StartupType Disabled -ErrorAction Stop
				$changed = $true
			}
		} else {
			throw "Unsupported platform."
		}
		if ($changed) {
			Write-Verbose "osqueryd disabled successfully."
			Get-OsQueryDaemonStatus
		}
	} catch {
		Write-Error "Failed to disable osqueryd: $($_.Exception.Message)"
	}
}
