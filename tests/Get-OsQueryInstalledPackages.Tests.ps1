#Requires -Version 7.0

BeforeAll {
    $modulePath = Resolve-Path (Join-Path $PSScriptRoot '..' 'osquery.psd1')
    Import-Module $modulePath -Force -WarningAction SilentlyContinue
}

AfterAll {
    Remove-Module osquery -Force -ErrorAction SilentlyContinue
}

Describe 'Get-OsQueryInstalledPackages' {
    It 'Queries all available package tables and includes tablename in output' {
        InModuleScope osquery {
            Mock Invoke-OsQueryTableQuery {
                param([string]$Query, [string]$ComputerName)

                if ($Query -like 'SELECT name FROM osquery_registry*') {
                    return @(
                        [pscustomobject]@{ name = 'deb_packages' },
                        [pscustomobject]@{ name = 'python_packages' }
                    )
                }

                if ($Query -like "SELECT *, 'deb_packages' AS tablename FROM deb_packages*") {
                    return @([pscustomobject]@{ package = 'curl'; tablename = 'deb_packages' })
                }

                if ($Query -like "SELECT *, 'python_packages' AS tablename FROM python_packages*") {
                    return @([pscustomobject]@{ package = 'pip'; tablename = 'python_packages' })
                }
            }

            $result = @(Get-OsQueryInstalledPackages)
            $result.Count | Should -Be 2
            $result.tablename | Should -Contain 'deb_packages'
            $result.tablename | Should -Contain 'python_packages'
        }
    }

    It 'Applies -Limit across combined results' {
        InModuleScope osquery {
            Mock Invoke-OsQueryTableQuery {
                param([string]$Query, [string]$ComputerName)

                if ($Query -like 'SELECT name FROM osquery_registry*') {
                    return @(
                        [pscustomobject]@{ name = 'deb_packages' },
                        [pscustomobject]@{ name = 'rpm_packages' }
                    )
                }

                if ($Query -like "SELECT *, 'deb_packages' AS tablename FROM deb_packages LIMIT 1;") {
                    return @([pscustomobject]@{ package = 'curl'; tablename = 'deb_packages' })
                }

                if ($Query -like "SELECT *, 'rpm_packages' AS tablename FROM rpm_packages*") {
                    return @([pscustomobject]@{ package = 'dnf'; tablename = 'rpm_packages' })
                }
            }

            $result = @(Get-OsQueryInstalledPackages -Limit 1)
            $result.Count | Should -Be 1
            $result[0].tablename | Should -Be 'deb_packages'
            Should -Invoke Invoke-OsQueryTableQuery -Times 0 -Exactly -ParameterFilter {
                $Query -like "*FROM rpm_packages*"
            }
        }
    }

    It 'Passes -ComputerName to registry and package table queries' {
        InModuleScope osquery {
            Mock Invoke-OsQueryTableQuery {
                param([string]$Query, [string]$ComputerName)

                if ($Query -like 'SELECT name FROM osquery_registry*') {
                    return @([pscustomobject]@{ name = 'homebrew_packages' })
                }

                if ($Query -like "SELECT *, 'homebrew_packages' AS tablename FROM homebrew_packages*") {
                    return @([pscustomobject]@{ package = 'wget'; tablename = 'homebrew_packages' })
                }
            }

            $null = Get-OsQueryInstalledPackages -ComputerName 'remote-01'
            Should -Invoke Invoke-OsQueryTableQuery -Times 2 -Exactly -ParameterFilter {
                $ComputerName -eq 'remote-01'
            }
        }
    }
}
