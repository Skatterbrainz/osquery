function Get-OsQuerySystemInfo {
	<#
	.SYNOPSIS
		Retrieves system hardware and OS information from osquery.
	.DESCRIPTION
		Queries 'system_info' for hardware details (hostname, CPU, memory, hardware model)
		and 'os_version' for OS details, then merges them into a single object per host.
	.PARAMETER ComputerName
		Remote computer to query. If not provided, queries locally.
	.EXAMPLE
		Get-OsQuerySystemInfo

		Returns a merged hardware and OS summary for the local machine.
	.EXAMPLE
		Get-OsQuerySystemInfo -ComputerName "server01"

		Returns system info for the remote computer "server01".
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$false)][string]$ComputerName
	)
	$invokeParams = @{}
	if (![string]::IsNullOrEmpty($ComputerName)) { $invokeParams.ComputerName = $ComputerName }

	$sysInfo = Invoke-OsQueryTableQuery -Query "SELECT * FROM system_info;" @invokeParams
	$osInfo  = Invoke-OsQueryTableQuery -Query "SELECT * FROM os_version;" @invokeParams

	if ($sysInfo -and $osInfo) {
		$merged = $sysInfo | Select-Object -Property *
		$osProps = $osInfo | Select-Object -ExcludeProperty name | Get-Member -MemberType NoteProperty | Select-Object -ExpandProperty Name
		foreach ($prop in $osProps) {
			$merged | Add-Member -NotePropertyName "os_$prop" -NotePropertyValue $osInfo.$prop -Force
		}
		$merged
	} else {
		$sysInfo
	}
}
