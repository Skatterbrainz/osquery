Get-ChildItem -Path "$PSScriptRoot\public" -Filter "*.ps1" | ForEach-Object {
	. $_.FullName
}

if (-not ($res = Test-OsQueryInstall -Detailed)) {
	Write-Warning "osquery is not installed on this system. Please install osquery to use this module."
}