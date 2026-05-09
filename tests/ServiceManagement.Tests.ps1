#Requires -Version 7.0
<#
.SYNOPSIS
    Pester v5 tests for osquery service management functions and aliases.
.NOTES
    Install Pester v5 before running:
        Install-PSResource Pester -Version '5.*'
    Run tests with:
        Invoke-Pester ./tests/ServiceManagement.Tests.ps1 -Output Detailed
#>

BeforeAll {
    $modulePath = Resolve-Path (Join-Path $PSScriptRoot '..' 'osquery.psd1')
    Import-Module $modulePath -Force -WarningAction SilentlyContinue
}

AfterAll {
    Remove-Module osquery -Force -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------------
# Aliases
# ---------------------------------------------------------------------------
Describe 'Alias Exports' {
    It 'Enable-OsQueryService resolves to Enable-OsQueryDaemon' {
        $alias = Get-Alias -Name 'Enable-OsQueryService' -ErrorAction SilentlyContinue
        $alias              | Should -Not -BeNullOrEmpty
        $alias.Definition   | Should -Be 'Enable-OsQueryDaemon'
    }

    It 'Disable-OsQueryService resolves to Disable-OsQueryDaemon' {
        $alias = Get-Alias -Name 'Disable-OsQueryService' -ErrorAction SilentlyContinue
        $alias              | Should -Not -BeNullOrEmpty
        $alias.Definition   | Should -Be 'Disable-OsQueryDaemon'
    }

    It 'Get-OsQueryServiceStatus resolves to Get-OsQueryDaemonStatus' {
        $alias = Get-Alias -Name 'Get-OsQueryServiceStatus' -ErrorAction SilentlyContinue
        $alias              | Should -Not -BeNullOrEmpty
        $alias.Definition   | Should -Be 'Get-OsQueryDaemonStatus'
    }

    It 'All three aliases are exported by the module manifest' {
        $exported = (Get-Module osquery).ExportedAliases.Keys
        $exported | Should -Contain 'Enable-OsQueryService'
        $exported | Should -Contain 'Disable-OsQueryService'
        $exported | Should -Contain 'Get-OsQueryServiceStatus'
    }
}

# ---------------------------------------------------------------------------
# New-OsQueryConfig
# ---------------------------------------------------------------------------
Describe 'New-OsQueryConfig' {
    Context 'File creation' {
        It 'Creates a config file at the specified path' {
            $path = Join-Path $TestDrive 'osquery.conf'
            New-OsQueryConfig -OutputPath $path
            $path | Should -Exist
        }

        It 'Returns a PSCustomObject with ConfigPath, FlagsPath, LogPath, PackageTable' {
            $path   = Join-Path $TestDrive 'osquery_props.conf'
            $result = New-OsQueryConfig -OutputPath $path
            $result                             | Should -BeOfType [PSCustomObject]
            $result.ConfigPath                  | Should -Be $path
            $result.PSObject.Properties.Name    | Should -Contain 'FlagsPath'
            $result.PSObject.Properties.Name    | Should -Contain 'LogPath'
            $result.PSObject.Properties.Name    | Should -Contain 'PackageTable'
        }

        It 'Produces valid JSON' {
            $path = Join-Path $TestDrive 'osquery_json.conf'
            New-OsQueryConfig -OutputPath $path
            { Get-Content $path -Raw | ConvertFrom-Json } | Should -Not -Throw
        }

        It 'Config contains the required top-level sections' {
            $path   = Join-Path $TestDrive 'osquery_sections.conf'
            New-OsQueryConfig -OutputPath $path
            $json   = Get-Content $path -Raw | ConvertFrom-Json
            $keys   = $json.PSObject.Properties.Name
            $keys   | Should -Contain 'options'
            $keys   | Should -Contain 'schedule'
            $keys   | Should -Contain 'decorators'
            $keys   | Should -Contain 'packs'
        }

        It 'Options reflect HostIdentifier and ScheduleSplayPercent parameters' {
            $path = Join-Path $TestDrive 'osquery_opts.conf'
            New-OsQueryConfig -OutputPath $path -HostIdentifier uuid -ScheduleSplayPercent 20
            $json = Get-Content $path -Raw | ConvertFrom-Json
            $json.options.host_identifier        | Should -Be 'uuid'
            $json.options.schedule_splay_percent | Should -Be 20
        }

        It 'Schedule contains the expected query entries' {
            $path  = Join-Path $TestDrive 'osquery_sched.conf'
            New-OsQueryConfig -OutputPath $path
            $json  = Get-Content $path -Raw | ConvertFrom-Json
            $keys  = $json.schedule.PSObject.Properties.Name
            $keys  | Should -Contain 'system_info'
            $keys  | Should -Contain 'os_version'
            $keys  | Should -Contain 'users'
            $keys  | Should -Contain 'processes'
            $keys  | Should -Contain 'listening_ports'
            $keys  | Should -Contain 'startup_items'
            $keys  | Should -Contain 'installed_packages'
        }

        It 'Decorators section contains at least one load query' {
            $path = Join-Path $TestDrive 'osquery_dec.conf'
            New-OsQueryConfig -OutputPath $path
            $json = Get-Content $path -Raw | ConvertFrom-Json
            $json.decorators.load.Count | Should -BeGreaterThan 0
        }

        It 'Writes an error when file exists and -Force is not specified' {
            $path = Join-Path $TestDrive 'osquery_exists.conf'
            New-OsQueryConfig -OutputPath $path
            { New-OsQueryConfig -OutputPath $path -ErrorAction Stop } | Should -Throw
        }

        It 'Overwrites an existing file when -Force is specified' {
            $path = Join-Path $TestDrive 'osquery_force.conf'
            New-OsQueryConfig -OutputPath $path
            { New-OsQueryConfig -OutputPath $path -Force } | Should -Not -Throw
        }

        It 'Does not create a file when -WhatIf is specified' {
            $path = Join-Path $TestDrive 'osquery_whatif.conf'
            New-OsQueryConfig -OutputPath $path -WhatIf
            $path | Should -Not -Exist
        }

        It 'Creates the output directory if it does not exist' {
            $dir  = Join-Path $TestDrive 'newsubdir'
            $path = Join-Path $dir 'osquery.conf'
            New-OsQueryConfig -OutputPath $path
            $dir  | Should -Exist
            $path | Should -Exist
        }
    }

    Context 'Flags file generation' {
        It 'Creates a flags file when -GenerateFlagsFile is specified' {
            $dir    = Join-Path $TestDrive 'flags1'
            $path   = Join-Path $dir 'osquery.conf'
            $result = New-OsQueryConfig -OutputPath $path -GenerateFlagsFile
            $result.FlagsPath | Should -Exist
        }

        It 'FlagsPath is null when -GenerateFlagsFile is omitted' {
            $path   = Join-Path $TestDrive 'osquery_noflags.conf'
            $result = New-OsQueryConfig -OutputPath $path -Force
            $result.FlagsPath | Should -BeNullOrEmpty
        }

        It 'Flags file references the correct config path' {
            $dir         = Join-Path $TestDrive 'flags2'
            $path        = Join-Path $dir 'osquery.conf'
            $result      = New-OsQueryConfig -OutputPath $path -GenerateFlagsFile
            $content     = Get-Content $result.FlagsPath -Raw
            $escapedPath = [regex]::Escape($path)
            $content | Should -Match '--config_path='
            $content | Should -Match $escapedPath
        }

        It 'Flags file contains required flag entries' {
            $dir    = Join-Path $TestDrive 'flags3'
            $path   = Join-Path $dir 'osquery.conf'
            $result = New-OsQueryConfig -OutputPath $path -GenerateFlagsFile
            $content = Get-Content $result.FlagsPath -Raw
            $content | Should -Match '--config_plugin=filesystem'
            $content | Should -Match '--logger_plugin=filesystem'
            $content | Should -Match '--database_path='
            $content | Should -Match '--pidfile='
        }
    }

    Context 'Package manager selection' {
        It 'Uses deb_packages when -PackageManager deb is specified' {
            $path = Join-Path $TestDrive 'osquery_deb.conf'
            New-OsQueryConfig -OutputPath $path -PackageManager deb
            $json = Get-Content $path -Raw | ConvertFrom-Json
            $json.schedule.installed_packages.query | Should -Match 'deb_packages'
        }

        It 'Uses rpm_packages when -PackageManager rpm is specified' {
            $path = Join-Path $TestDrive 'osquery_rpm.conf'
            New-OsQueryConfig -OutputPath $path -PackageManager rpm
            $json = Get-Content $path -Raw | ConvertFrom-Json
            $json.schedule.installed_packages.query | Should -Match 'rpm_packages'
        }

        It 'Returns the correct PackageTable in the output object' {
            $path   = Join-Path $TestDrive 'osquery_ptable.conf'
            $result = New-OsQueryConfig -OutputPath $path -PackageManager rpm
            $result.PackageTable | Should -Be 'rpm_packages'
        }

        It 'Rejects invalid PackageManager values' {
            $path = Join-Path $TestDrive 'osquery_bad.conf'
            { New-OsQueryConfig -OutputPath $path -PackageManager 'invalid' } | Should -Throw
        }
    }
}

# ---------------------------------------------------------------------------
# Test-ElevatedPrivilege (private helper - tested via InModuleScope)
# ---------------------------------------------------------------------------
Describe 'Test-ElevatedPrivilege (private)' {
    It 'Returns a boolean' {
        InModuleScope osquery {
            $result = Test-ElevatedPrivilege
            $result | Should -BeOfType [bool]
        }
    }

    It 'Returns $true when mocked as root' {
        InModuleScope osquery {
            Mock id { '0' }
            if (-not $IsWindows) {
                Test-ElevatedPrivilege | Should -BeTrue
            }
        }
    }

    It 'Returns $false when mocked as non-root' {
        InModuleScope osquery {
            Mock id { '1000' }
            if (-not $IsWindows) {
                Test-ElevatedPrivilege | Should -BeFalse
            }
        }
    }
}

# ---------------------------------------------------------------------------
# Enable-OsQueryDaemon
# ---------------------------------------------------------------------------
Describe 'Enable-OsQueryDaemon' {
    Context 'Privilege enforcement' {
        It 'Writes an error and returns when not elevated' {
            InModuleScope osquery {
                Mock Test-ElevatedPrivilege { $false }
                $err = $null
                Enable-OsQueryDaemon -ErrorVariable err -ErrorAction SilentlyContinue
                $err | Should -Not -BeNullOrEmpty
            }
        }

        It 'Does not call systemctl when not elevated' {
            InModuleScope osquery {
                Mock Test-ElevatedPrivilege { $false }
                Mock systemctl { }
                Enable-OsQueryDaemon -ErrorAction SilentlyContinue
                Should -Invoke systemctl -Times 0 -Exactly
            }
        }
    }

    Context 'Config file warning' {
        It 'Issues a warning when the config file does not exist' {
            InModuleScope osquery {
                Mock Test-ElevatedPrivilege { $true }
                Mock systemctl { $global:LASTEXITCODE = 0 }
                Mock Get-OsQueryDaemonStatus { [PSCustomObject]@{ Name='osqueryd'; Status='active'; Enabled=$true; PID=$null; Platform='Linux' } }
                $warn = $null
                Enable-OsQueryDaemon -ConfigPath '/nonexistent/path/osquery.conf' -WarningVariable warn -WarningAction SilentlyContinue
                $warn | Should -Not -BeNullOrEmpty
            }
        }

        It 'Does not warn when the config file exists' {
            InModuleScope osquery {
                Mock Test-ElevatedPrivilege { $true }
                Mock systemctl { $global:LASTEXITCODE = 0 }
                Mock Get-OsQueryDaemonStatus { [PSCustomObject]@{ Name='osqueryd'; Status='active'; Enabled=$true; PID=$null; Platform='Linux' } }
                $tmpConf = New-TemporaryFile
                $warn    = $null
                Enable-OsQueryDaemon -ConfigPath $tmpConf.FullName -WarningVariable warn -WarningAction SilentlyContinue
                Remove-Item $tmpConf -Force
                $warn | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Linux - systemctl calls' -Skip:(-not $IsLinux) {
        It 'Invokes systemctl enable and systemctl start when elevated' {
            InModuleScope osquery {
                Mock Test-ElevatedPrivilege { $true }
                Mock systemctl { $global:LASTEXITCODE = 0 }
                Mock Get-OsQueryDaemonStatus { [PSCustomObject]@{ Name='osqueryd'; Status='active'; Enabled=$true; PID=1234; Platform='Linux' } }
                $tmpConf = New-TemporaryFile
                Enable-OsQueryDaemon -ConfigPath $tmpConf.FullName
                Remove-Item $tmpConf -Force
                Should -Invoke systemctl -Times 2 -Exactly
            }
        }

        It 'Returns the daemon status object on success' {
            InModuleScope osquery {
                Mock Test-ElevatedPrivilege { $true }
                Mock systemctl { $global:LASTEXITCODE = 0 }
                Mock Get-OsQueryDaemonStatus {
                    [PSCustomObject]@{ Name='osqueryd'; Status='active'; Enabled=$true; PID=1234; Platform='Linux' }
                }
                $tmpConf = New-TemporaryFile
                $result  = Enable-OsQueryDaemon -ConfigPath $tmpConf.FullName
                Remove-Item $tmpConf -Force
                $result.Status  | Should -Be 'active'
                $result.Enabled | Should -BeTrue
            }
        }
    }
}

# ---------------------------------------------------------------------------
# Disable-OsQueryDaemon
# ---------------------------------------------------------------------------
Describe 'Disable-OsQueryDaemon' {
    Context 'Privilege enforcement' {
        It 'Writes an error and returns when not elevated' {
            InModuleScope osquery {
                Mock Test-ElevatedPrivilege { $false }
                $err = $null
                Disable-OsQueryDaemon -ErrorVariable err -ErrorAction SilentlyContinue
                $err | Should -Not -BeNullOrEmpty
            }
        }

        It 'Does not call systemctl when not elevated' {
            InModuleScope osquery {
                Mock Test-ElevatedPrivilege { $false }
                Mock systemctl { }
                Disable-OsQueryDaemon -ErrorAction SilentlyContinue
                Should -Invoke systemctl -Times 0 -Exactly
            }
        }
    }

    Context 'WhatIf support' {
        It 'Does not invoke systemctl when -WhatIf is specified' {
            InModuleScope osquery {
                Mock Test-ElevatedPrivilege { $true }
                Mock systemctl { }
                Disable-OsQueryDaemon -WhatIf
                Should -Invoke systemctl -Times 0 -Exactly
            }
        }
    }

    Context 'Linux - systemctl calls' -Skip:(-not $IsLinux) {
        It 'Invokes systemctl stop and systemctl disable when elevated' {
            InModuleScope osquery {
                Mock Test-ElevatedPrivilege { $true }
                Mock systemctl { $global:LASTEXITCODE = 0 }
                Mock Get-OsQueryDaemonStatus { [PSCustomObject]@{ Name='osqueryd'; Status='inactive'; Enabled=$false; PID=$null; Platform='Linux' } }
                Disable-OsQueryDaemon
                Should -Invoke systemctl -Times 2 -Exactly
            }
        }

        It 'Returns the daemon status object on success' {
            InModuleScope osquery {
                Mock Test-ElevatedPrivilege { $true }
                Mock systemctl { $global:LASTEXITCODE = 0 }
                Mock Get-OsQueryDaemonStatus {
                    [PSCustomObject]@{ Name='osqueryd'; Status='inactive'; Enabled=$false; PID=$null; Platform='Linux' }
                }
                $result = Disable-OsQueryDaemon
                $result.Status  | Should -Be 'inactive'
                $result.Enabled | Should -BeFalse
            }
        }
    }
}

# ---------------------------------------------------------------------------
# Get-OsQueryDaemonStatus / Get-OsQueryServiceStatus
# ---------------------------------------------------------------------------
Describe 'Get-OsQueryDaemonStatus' {
    Context 'Output shape' {
        It 'Returns an object with Name, Platform, Status, Enabled, PID properties' {
            InModuleScope osquery {
                Mock systemctl {
                    if ($args -contains 'is-active')  { return 'active' }
                    if ($args -contains 'is-enabled') { return 'enabled' }
                    if ($args -contains 'show')        { return '1234' }
                }
                if ($IsLinux) {
                    $result = Get-OsQueryDaemonStatus
                    $props  = $result.PSObject.Properties.Name
                    $props  | Should -Contain 'Name'
                    $props  | Should -Contain 'Platform'
                    $props  | Should -Contain 'Status'
                    $props  | Should -Contain 'Enabled'
                    $props  | Should -Contain 'PID'
                }
            }
        }
    }

    Context 'Linux - mocked systemctl' -Skip:(-not $IsLinux) {
        It 'Reports Status as active when systemctl is-active returns active' {
            InModuleScope osquery {
                Mock systemctl {
                    if ($args -contains 'is-active')  { return 'active' }
                    if ($args -contains 'is-enabled') { return 'enabled' }
                    if ($args -contains 'show')        { return '5678' }
                }
                $result = Get-OsQueryDaemonStatus
                $result.Status   | Should -Be 'active'
                $result.Platform | Should -Be 'Linux'
                $result.Enabled  | Should -BeTrue
                $result.PID      | Should -Be 5678
            }
        }

        It 'Reports Enabled as $false when systemctl is-enabled returns disabled' {
            InModuleScope osquery {
                Mock systemctl {
                    if ($args -contains 'is-active')  { return 'inactive' }
                    if ($args -contains 'is-enabled') { return 'disabled' }
                    if ($args -contains 'show')        { return '0' }
                }
                $result = Get-OsQueryDaemonStatus
                $result.Enabled | Should -BeFalse
                $result.PID     | Should -BeNullOrEmpty
            }
        }

        It 'PID is null when MainPID is 0' {
            InModuleScope osquery {
                Mock systemctl {
                    if ($args -contains 'is-active')  { return 'inactive' }
                    if ($args -contains 'is-enabled') { return 'disabled' }
                    if ($args -contains 'show')        { return '0' }
                }
                $result = Get-OsQueryDaemonStatus
                $result.PID | Should -BeNullOrEmpty
            }
        }
    }

    Context 'Alias equivalence' {
        It 'Get-OsQueryServiceStatus produces the same output as Get-OsQueryDaemonStatus' {
            InModuleScope osquery {
                if ($IsLinux) {
                    Mock systemctl {
                        if ($args -contains 'is-active')  { return 'active' }
                        if ($args -contains 'is-enabled') { return 'enabled' }
                        if ($args -contains 'show')        { return '999' }
                    }
                    $via_daemon  = Get-OsQueryDaemonStatus
                    $via_service = Get-OsQueryServiceStatus
                    $via_service.Status  | Should -Be $via_daemon.Status
                    $via_service.Enabled | Should -Be $via_daemon.Enabled
                    $via_service.PID     | Should -Be $via_daemon.PID
                }
            }
        }
    }
}
