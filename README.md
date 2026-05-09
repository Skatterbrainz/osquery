# osquery

PowerShell module for querying system information via [osquery](https://osquery.io/)

![PowerShell](https://img.shields.io/badge/PowerShell-7.0%2B-blue)
![Platform](https://img.shields.io/badge/platform-Windows-blue)
![Platform](https://img.shields.io/badge/platform-MacOS-green)
![Platform](https://img.shields.io/badge/platform-Linux-orange)
![License](https://img.shields.io/badge/license-MIT-green)

Idiomatic PowerShell functions that wrap `osqueryi` to query operating system and hardware information using SQL. Every function returns parsed `PSCustomObject` output, so results plug directly into `Format-Table`, `Where-Object`, `Export-Csv`, and the rest of the PowerShell ecosystem.

## 🎯 What is osquery?

[osquery](https://github.com/osquery) exposes an operating system as a high-performance relational database. This allows you to write SQL-based queries to explore operating system data. With osquery, SQL tables represent abstract concepts such as running processes, loaded kernel modules, open network connections, browser plugins, hardware events or file hashes. More information at [https://github.com/osquery](https://github.com/osquery)

**osquery helps MacOS, and Linux support some of the abstraction found with WMI (Windows Management Instrumentation) on Windows.**

## 🎯 Module Overview

This module exposes 25 public functions covering processes, users, networking, packages, security, storage, daemon lifecycle management, and more. All queries run through `osqueryi --json` under the hood and are deserialized into structured objects. Most functions support a `-ComputerName` parameter for remote execution via PowerShell Remoting.

## ✨ Features

- 🖥️ **System Info** - Hostname, CPU, memory, OS version, and disk/mount details
- 👤 **Users & Access** - Local users, groups, logged-in sessions, and sudoers configuration
- ⚙️ **Processes & Services** - Running processes, startup items, and scheduled cron jobs
- 📦 **Packages** - Installed packages across deb, rpm, Chocolatey, Homebrew, and Python
- 🌐 **Networking** - Active sockets, listening ports, and interface IP addresses
- 🔐 **Security** - Firewall rules and installed certificates
- 🐳 **Containers** - Docker container and image inventory
- 🔍 **Schema Explorer** - Browse osquery tables interactively and run ad-hoc SQL queries
- 🛠️ **Daemon Management** - Generate scaffold config, enable/disable osqueryd as a system service, and check daemon status

## Requirements

- PowerShell 7.0 or higher
- `osqueryi` installed and available in your `PATH`
- Elevated privileges (root/Administrator) required for some tables (e.g. `sudoers`, `iptables`) and all daemon management functions

## Installation

### From PowerShell Gallery

```powershell
Install-PSResource osquery
```

### From GitHub

1. **Clone the repository**
   ```bash
   git clone https://github.com/Skatterbrainz/osquery.git
   cd osquery
   ```

2. **Import the module**
   ```powershell
   Import-Module ./osquery.psd1
   ```

## Getting osquery

- Home page: [https://osquery.io](https://osquery.io/)
- Downloads: [https://osquery.io/downloads/official](https://osquery.io/downloads/official)
- Documentation: [https://osquery.readthedocs.io/en/stable/](https://osquery.readthedocs.io/en/stable/)
- Schema Reference: [https://osquery.io/schema](https://osquery.io/schema)

For platform-specific installation guidance, run `Show-OsQueryInstall` after importing the module.

## Usage

```powershell
# Import the module
Import-Module osquery

# Verify osquery is detected
Test-OsQueryInstall -Detailed

# Browse available tables interactively
Get-OsQueryTableSample

# Run an ad-hoc SQL query
Invoke-OsQueryTableQuery -Query "SELECT pid, name, path FROM processes WHERE name LIKE 'pwsh%';"
```

## 📋 Examples

### Get a hardware and OS summary

```powershell
Get-OsQuerySystemInfo | Select-Object hostname, cpu_brand, physical_memory, os_name, os_version
```

### Find all processes matching a name

```powershell
Get-OsQueryProcesses -Name "pwsh" | Format-Table pid, name, path, resident_size
```

### List listening ports with their owning process

```powershell
Get-OsQueryNetworkConnections -Listening |
    Select-Object pid, port, protocol, address |
    Sort-Object port |
    Format-Table
```

### Audit installed deb packages and export to CSV

```powershell
Get-OsQueryInstalledPackages | Export-Csv -Path "./packages.csv" -NoTypeInformation
```

## 📖 Function Reference

### Query & Schema

| Function | Description |
|---|---|
| `Invoke-OsQueryTableQuery` | Execute any osquery SQL query and return structured objects |
| `Get-OsQuerySchema` | List tables registered in the osquery schema by registry type |
| `Get-OsQueryTableSample` | Run a sample `SELECT *` query against a chosen table |

### System Info

| Function | Description |
|---|---|
| `Get-OsQuerySystemInfo` | Merged hardware and OS summary (`system_info` + `os_version`) |
| `Get-OsQueryDisk` | Mount points (Linux/macOS) or disk info (Windows) |
| `Get-OsQueryFiles` | File listing and metadata for a given directory path |

### Users & Access

| Function | Description |
|---|---|
| `Get-OsQueryUsers` | Local user accounts |
| `Get-OsQueryGroups` | Local groups |
| `Get-OsQueryLoggedInUsers` | Active login sessions |
| `Get-OsQuerySudoers` | Parsed sudoers configuration (Linux/macOS, requires root) |

### Processes & Services

| Function | Description |
|---|---|
| `Get-OsQueryProcesses` | Running processes; filter by `-Name` |
| `Get-OsQueryServices` | Services (Windows) or startup items (Linux/macOS) |
| `Get-OsQueryCronJobs` | Crontab entries (Linux/macOS) |

### Packages & Containers

| Function | Description |
|---|---|
| `Get-OsQueryInstalledPackages` | Installed packages; auto-detects deb/rpm/Chocolatey/Homebrew/Python |
| `Get-OsQueryDockerContainers` | Docker containers; `-IncludeImages` adds image inventory |

### Networking

| Function | Description |
|---|---|
| `Get-OsQueryNetworkConnections` | Open sockets (`process_open_sockets`); `-Listening` for listening ports only |
| `Get-OsQueryIPAddress` | Interface IP address information |

### Security

| Function | Description |
|---|---|
| `Get-OsQueryFirewall` | Firewall rules (`iptables` / `windows_firewall_rules` / `alf`) |
| `Get-OsQueryCertificates` | Installed certificates |

### Daemon Management

| Function | Alias | Description |
|---|---|---|
| `New-OsQueryConfig` | | Generate a scaffold `osquery.conf` with scheduled queries; optionally write `osquery.flags`. Supports `-WhatIf` |
| `Enable-OsQueryDaemon` | `Enable-OsQueryService` | Enable and start osqueryd (`systemctl` / `launchctl` / Windows Service). Requires elevation |
| `Disable-OsQueryDaemon` | `Disable-OsQueryService` | Stop and disable osqueryd. Supports `-WhatIf`. Requires elevation |
| `Get-OsQueryDaemonStatus` | `Get-OsQueryServiceStatus` | Return daemon status object with `Name`, `Platform`, `Status`, `Enabled`, `PID` |

### Utility

| Function | Description |
|---|---|
| `Test-OsQueryInstall` | Check whether osqueryi is in PATH; `-Detailed` returns version and path |
| `Show-OsQueryInstall` | Open platform-specific installation docs in the default browser; `-Downloads` opens the downloads page |

## Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest new features or cmdlets
- Improve documentation
- Submit pull requests

Please open an [issue](https://github.com/Skatterbrainz/osquery/issues) or submit a pull request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Version History

- 2.1.0 - 2026-05-09
  - Added `New-OsQueryConfig` to generate a scaffold `osquery.conf` (8 scheduled queries, decorators, packs placeholder) and optional `osquery.flags` companion file
  - Added `Enable-OsQueryDaemon` / `Enable-OsQueryService` to enable and start osqueryd cross-platform
  - Added `Disable-OsQueryDaemon` / `Disable-OsQueryService` to stop and disable osqueryd; supports `-WhatIf`
  - Added `Get-OsQueryDaemonStatus` / `Get-OsQueryServiceStatus` to return structured daemon status
  - Added private `Test-ElevatedPrivilege` helper (Linux/macOS: `id -u`; Windows: `WindowsPrincipal`)
  - Added `tests/ServiceManagement.Tests.ps1` with 42 Pester v5 tests covering aliases, config generation, privilege gates, WhatIf behavior, and mocked systemctl interactions
  - Fixed `Write-Verbose` null-guard in Enable/Disable functions when systemctl returns no output
  - Fixed `Disable-OsQueryDaemon` to skip status call when `-WhatIf` suppresses changes (`$changed` flag)
  - Fixed `Get-OsQueryDaemonStatus` null-safety for `.Trim()` on systemctl output
- 2.0.0 - 2026-05-09
  - Added 13 new functions: `Get-OsQueryProcesses`, `Get-OsQueryInstalledPackages`, `Get-OsQueryNetworkConnections`, `Get-OsQuerySystemInfo`, `Get-OsQueryServices`, `Get-OsQueryGroups`, `Get-OsQueryDisk`, `Get-OsQueryFirewall`, `Get-OsQueryCertificates`, `Get-OsQueryLoggedInUsers`, `Get-OsQuerySudoers`, `Get-OsQueryCronJobs`, `Get-OsQueryDockerContainers`
  - Added `Show-OsQueryInstall` to open platform-specific installation docs in the default browser
  - Added private `Get-OsQueryBinaryPath` helper using `Get-Command` for cross-platform binary resolution
  - Fixed cross-platform path separator in module loader (`Join-Path`)
  - Fixed `Test-OsQueryInstall` return values (`$true`/`$false` instead of strings)
  - Fixed `Get-OsQuerySchema` variable scope bug in remote `Invoke-Command` scriptblock
  - Fixed `Invoke-OsQueryTableQuery` to resolve `osqueryi` path dynamically
  - Added `ComputerName` parameter to `Get-OsQueryIPAddress` and `Get-OsQueryUsers`
  - Added elevated privilege check to `Get-OsQuerySudoers`
  - Set `PowerShellVersion = '7.0'` and `VariablesToExport = @()` in manifest
- 1.0.4 - 2026-04-29
  - Initial public release with `Get-OsQueryFiles`, `Get-OsQueryIPAddress`, `Get-OsQuerySchema`, `Get-OsQueryTableSample`, `Get-OsQueryUsers`, `Invoke-OsQueryTableQuery`, `Test-OsQueryInstall`
