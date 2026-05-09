foreach ($dir in @('private', 'public')) {
	$dirPath = Join-Path $PSScriptRoot $dir
	if (Test-Path $dirPath) {
		Get-ChildItem -Path $dirPath -Filter '*.ps1' | ForEach-Object { . $_.FullName }
	}
}

if (-not (Get-OsQueryBinaryPath)) {
	Write-Warning "osqueryi was not found in PATH. Please install osquery and ensure it is accessible."
	Write-Information "Visit https://osquery.readthedocs.io/ for installation instructions."
}
