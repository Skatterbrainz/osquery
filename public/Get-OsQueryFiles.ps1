function Get-OsQueryFiles {
	<#
	.SYNOPSIS
		Retrieves file information from osquery based on the specified path.
	.DESCRIPTION
		This function retrieves file information from osquery by executing a query against the osquery file table.
	.PARAMETER Path
		The directory path to search for files. The function will retrieve files within this directory.
	.PARAMETER ComputerName
		The name of the remote computer to execute the query on. If not provided, the query will be executed locally.
	.PARAMETER NoWarning
		Switch to suppress the case sensitivity warning on Linux systems.
	.EXAMPLE
		Get-OsQueryFiles -Path "/etc/"
		
		Retrieves file information from the /etc/ directory on a Linux system.
	.EXAMPLE
		Get-OsQueryFiles -Path "C:\Windows\System32\" -ComputerName "RemotePC"
		
		Retrieves file information from the C:\Windows\System32\ directory on the remote computer named RemotePC.
	.EXAMPLE
		Get-OsQueryFiles -Path "/Users/Shared/" -NoWarning
		
		Retrieves file information from the /Users/Shared/ directory on a macOS system without displaying a case sensitivity warning.
	#>
	param (
		[parameter(Mandatory=$true)][string]$Path,
		[parameter(Mandatory=$false)][string]$ComputerName,
		[parameter(Mandatory=$false)][switch]$NoWarning
	)
	if ($IsLinux -and $Path.EndsWith('/') -eq $false) {
		$Path += '/'
	} elseif ($IsMacOS -and $Path.EndsWith('/') -eq $false) {
		$Path += '/'
	} elseif ($IsWindows -and $Path.EndsWith('\') -eq $false) {
		$Path += '\'
	}
	if ($IsLinux -and (-not $NoWarning)) {
		Write-Warning "Note: Linux file system queries are typically case sensitive."
	}
	Invoke-OsQueryTableQuery -Query "select filename,size from file where path like '$Path%' and filename != '.';" -ComputerName $ComputerName
}