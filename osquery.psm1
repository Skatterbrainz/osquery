# Check for osquery installation

if ($IsLinux) {
	if (-not(Test-Path -Path "/opt/osquery/bin/osqueryd")) {
		Write-Warning "osqueryd not found in /opt/osquery/bin/. Please ensure osquery is installed."
		return
	}
} elseif ($IsWindows) {
	if (-not(Test-Path -Path "C:\Program Files\osquery\osqueryd.exe")) {
		Write-Warning "osqueryd not found in C:\Program Files\osquery\. Please ensure osquery is installed."
		return
	}
} elseif ($IsMacOS) {
	if (-not(Test-Path -Path "/opt/osquery/lib/osquery.app")) {
		Write-Warning "osqueryd not found in /opt/osquery/lib/. Please ensure osquery is installed."
		return
	}
} else {
	Write-Warning "Unsupported operating system."
	return
}

Get-ChildItem -Path "$PSScriptRoot\public" -Filter "*.ps1" | ForEach-Object {
	. $_.FullName
}