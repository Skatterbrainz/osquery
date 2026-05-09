function Enable-OsQueryDaemon {
	<#
	.SYNOPSIS
		Enables and starts the osqueryd daemon as a system service.
	.DESCRIPTION
		On Linux, uses systemctl to enable and start osqueryd.
		On macOS, loads the LaunchDaemon plist via launchctl.
		On Windows, sets the service to automatic startup and starts it.
		Requires elevated privileges (root/Administrator).
	.PARAMETER ConfigPath
		Path to the osquery.conf file. Used only to warn if the config is missing before starting.
		Defaults to the platform system path.
	.EXAMPLE
		Enable-OsQueryDaemon

		Enables and starts osqueryd using system defaults.
	.EXAMPLE
		Enable-OsQueryDaemon -ConfigPath "/etc/osquery/osquery.conf"

		Enables the daemon after verifying the config file exists at the given path.
	#>
	[CmdletBinding()]
	[Alias('Enable-OsQueryService')]
	param (
		[parameter(Mandatory=$false)][string]$ConfigPath
	)

	if (-not (Test-ElevatedPrivilege)) {
		Write-Error "Enabling the osqueryd daemon requires elevated privileges. Re-run as root or Administrator."
		return
	}

	# Resolve default config path per platform for existence check
	if ([string]::IsNullOrEmpty($ConfigPath)) {
		$ConfigPath = if ($IsWindows)    { 'C:\Program Files\osquery\osquery.conf' }
		              elseif ($IsMacOS)  { '/var/osquery/osquery.conf' }
		              else               { '/etc/osquery/osquery.conf' }
	}
	if (-not (Test-Path $ConfigPath)) {
		Write-Warning "Config file not found at '$ConfigPath'. osqueryd may not function correctly. Run New-OsQueryConfig to generate one."
	}

	try {
		if ($IsLinux) {
			Write-Verbose "Enabling osqueryd via systemctl..."
			$enableOut = & systemctl enable osqueryd 2>&1
			$startOut  = & systemctl start  osqueryd 2>&1
			if ($LASTEXITCODE -ne 0) { throw ($startOut -join ' ') }
			if ($enableOut) { Write-Verbose ($enableOut -join ' ') }
			if ($startOut)  { Write-Verbose ($startOut  -join ' ') }
		} elseif ($IsMacOS) {
			$plist = '/Library/LaunchDaemons/com.facebook.osqueryd.plist'
			if (-not (Test-Path $plist)) {
				throw "LaunchDaemon plist not found at '$plist'. Ensure osquery is installed."
			}
			Write-Verbose "Loading osqueryd via launchctl..."
			$out = & launchctl load -w $plist 2>&1
			if ($LASTEXITCODE -ne 0) { throw ($out -join ' ') }
		} elseif ($IsWindows) {
			Write-Verbose "Setting osqueryd service to automatic and starting..."
			Set-Service  -Name osqueryd -StartupType Automatic -ErrorAction Stop
			Start-Service -Name osqueryd -ErrorAction Stop
		} else {
			throw "Unsupported platform."
		}
		Write-Verbose "osqueryd enabled successfully."
		Get-OsQueryDaemonStatus
	} catch {
		Write-Error "Failed to enable osqueryd: $($_.Exception.Message)"
	}
}
