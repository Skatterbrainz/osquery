function New-OsQueryConfig {
	<#
	.SYNOPSIS
		Generates a scaffold osquery daemon configuration file.
	.DESCRIPTION
		Creates a JSON osquery.conf with sensible defaults including scheduled queries
		for system info, users, processes, networking, and installed packages.
		Optionally generates a companion osquery.flags file.
		Writing to system paths requires elevated privileges (root/Administrator).
	.PARAMETER OutputPath
		Full path to write osquery.conf. Defaults to the platform-appropriate system path.
	.PARAMETER LogPath
		Directory for osqueryd log output. Defaults to the platform log directory.
	.PARAMETER HostIdentifier
		How the host identifies itself in logs. Valid values: hostname, uuid, instance. Default: hostname.
	.PARAMETER ScheduleSplayPercent
		Percentage to randomize query timing to avoid thundering herd. Default: 10.
	.PARAMETER PackageManager
		Package table to include in the scheduled package query. Auto-detected if not specified.
	.PARAMETER GenerateFlagsFile
		If specified, also writes an osquery.flags companion file alongside the config.
	.PARAMETER Force
		Overwrite an existing config file without prompting.
	.EXAMPLE
		New-OsQueryConfig

		Writes a scaffold config to the platform default path.
	.EXAMPLE
		New-OsQueryConfig -OutputPath "/tmp/osquery.conf" -GenerateFlagsFile -Force

		Writes config and flags file to /tmp/ without elevation, overwriting if present.
	.EXAMPLE
		New-OsQueryConfig -HostIdentifier uuid -ScheduleSplayPercent 20 -PackageManager rpm

		Generates a config using UUID host identification and the rpm_packages table.
	#>
	[CmdletBinding(SupportsShouldProcess)]
	param (
		[parameter(Mandatory=$false)][string]$OutputPath,
		[parameter(Mandatory=$false)][string]$LogPath,
		[parameter(Mandatory=$false)]
		[ValidateSet('hostname', 'uuid', 'instance')]
		[string]$HostIdentifier = 'hostname',
		[parameter(Mandatory=$false)]
		[ValidateRange(0, 100)]
		[int]$ScheduleSplayPercent = 10,
		[parameter(Mandatory=$false)]
		[ValidateSet('deb', 'rpm', 'chocolatey', 'homebrew')]
		[string]$PackageManager,
		[parameter(Mandatory=$false)][switch]$GenerateFlagsFile,
		[parameter(Mandatory=$false)][switch]$Force
	)

	# Platform-specific default paths
	if ($IsWindows) {
		$defaultConfigDir = 'C:\Program Files\osquery'
		$defaultLogPath   = 'C:\Program Files\osquery\log'
		$defaultDbDir     = 'C:\Program Files\osquery'
	} elseif ($IsMacOS) {
		$defaultConfigDir = '/var/osquery'
		$defaultLogPath   = '/var/log/osquery'
		$defaultDbDir     = '/var/osquery'
	} else {
		$defaultConfigDir = '/etc/osquery'
		$defaultLogPath   = '/var/log/osquery'
		$defaultDbDir     = '/var/osquery'
	}

	if ([string]::IsNullOrEmpty($OutputPath)) { $OutputPath = Join-Path $defaultConfigDir 'osquery.conf' }
	if ([string]::IsNullOrEmpty($LogPath))    { $LogPath    = $defaultLogPath }

	# Warn if writing to a system path without elevation
	$systemPrefixes = @('/etc/', '/var/', 'C:\Program Files\')
	$needsElevation = $systemPrefixes | Where-Object { $OutputPath.StartsWith($_) }
	if ($needsElevation -and -not (Test-ElevatedPrivilege)) {
		Write-Warning "Writing to '$OutputPath' typically requires elevated privileges. Run as root or Administrator if the write fails."
	}

	# Auto-detect package manager
	if ([string]::IsNullOrEmpty($PackageManager)) {
		$PackageManager = if ($IsWindows)              { 'chocolatey' }
		                  elseif ($IsMacOS)             { 'homebrew' }
		                  elseif (Test-Path '/usr/bin/rpm') { 'rpm' }
		                  else                          { 'deb' }
	}
	$packageTable = switch ($PackageManager) {
		'deb'        { 'deb_packages' }
		'rpm'        { 'rpm_packages' }
		'chocolatey' { 'chocolatey_packages' }
		'homebrew'   { 'homebrew_packages' }
	}

	$config = [ordered]@{
		options = [ordered]@{
			host_identifier        = $HostIdentifier
			schedule_splay_percent = $ScheduleSplayPercent
			logger_plugin          = 'filesystem'
			logger_path            = $LogPath
			log_result_events      = $true
			log_snapshot_on_exit   = $true
			worker_threads         = 2
			enable_monitor         = $true
			disable_watchdog       = $false
			watchdog_level         = 0
			events_expiry          = 3600
			verbose                = $false
		}
		schedule = [ordered]@{
			system_info = [ordered]@{
				query       = 'SELECT hostname, cpu_brand, physical_memory, hardware_model FROM system_info;'
				interval    = 3600
				description = 'System hardware summary'
			}
			os_version = [ordered]@{
				query       = 'SELECT name, version, build, platform FROM os_version;'
				interval    = 3600
				description = 'Operating system version'
			}
			users = [ordered]@{
				query       = 'SELECT uid, username, description, directory, shell FROM users;'
				interval    = 300
				description = 'Local user accounts'
			}
			logged_in_users = [ordered]@{
				query       = "SELECT user, type, tty, host, datetime(time, 'unixepoch') AS login_time FROM logged_in_users;"
				interval    = 60
				description = 'Currently logged-in users'
			}
			processes = [ordered]@{
				query       = 'SELECT pid, name, path, cmdline, uid FROM processes;'
				interval    = 60
				description = 'Running processes'
			}
			listening_ports = [ordered]@{
				query       = 'SELECT pid, port, protocol, family, address FROM listening_ports;'
				interval    = 300
				description = 'Network listening ports'
			}
			startup_items = [ordered]@{
				query       = 'SELECT name, path, args, type, status FROM startup_items;'
				interval    = 3600
				description = 'Startup items and persistence'
			}
			installed_packages = [ordered]@{
				query       = "SELECT name, version, arch FROM $packageTable;"
				interval    = 3600
				description = "Installed packages ($packageTable)"
			}
		}
		decorators = [ordered]@{
			load = @(
				'SELECT uuid AS host_uuid FROM system_info;'
				'SELECT user AS username FROM logged_in_users ORDER BY time DESC LIMIT 1;'
			)
		}
		packs = [ordered]@{}
	}

	# Ensure output directory exists
	$configDir = Split-Path $OutputPath -Parent
	if (-not (Test-Path $configDir)) {
		if ($PSCmdlet.ShouldProcess($configDir, 'Create directory')) {
			New-Item -ItemType Directory -Path $configDir -Force | Out-Null
		}
	}

	# Check for existing file
	if ((Test-Path $OutputPath) -and -not $Force.IsPresent) {
		Write-Error "Config already exists at '$OutputPath'. Use -Force to overwrite."
		return
	}

	$json = $config | ConvertTo-Json -Depth 10
	if ($PSCmdlet.ShouldProcess($OutputPath, 'Write osquery.conf')) {
		Set-Content -Path $OutputPath -Value $json -Encoding UTF8
		Write-Verbose "Config written: $OutputPath"
	}

	# Optional flags file
	$flagsPath = $null
	if ($GenerateFlagsFile.IsPresent) {
		$flagsPath = Join-Path $configDir 'osquery.flags'
		$flags = @(
			"--config_plugin=filesystem"
			"--config_path=$OutputPath"
			"--logger_plugin=filesystem"
			"--logger_path=$LogPath"
			"--pidfile=$(Join-Path $defaultDbDir 'osquery.pidfile')"
			"--database_path=$(Join-Path $defaultDbDir 'osquery.db')"
			"--disable_watchdog=false"
		)
		if ($PSCmdlet.ShouldProcess($flagsPath, 'Write osquery.flags')) {
			Set-Content -Path $flagsPath -Value ($flags -join "`n") -Encoding UTF8
			Write-Verbose "Flags file written: $flagsPath"
		}
	}

	[PSCustomObject]@{
		ConfigPath   = $OutputPath
		FlagsPath    = $flagsPath
		LogPath      = $LogPath
		PackageTable = $packageTable
	}
}
