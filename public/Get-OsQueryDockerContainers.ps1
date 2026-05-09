function Get-OsQueryDockerContainers {
	<#
	.SYNOPSIS
		Retrieves Docker container information from osquery.
	.DESCRIPTION
		Queries the 'docker_containers' table and optionally 'docker_images'.
		Requires the Docker daemon to be running and osquery to have access to the Docker socket.
	.PARAMETER IncludeImages
		If specified, also queries 'docker_images' and returns both containers and images.
	.PARAMETER Limit
		Maximum number of records to return per table. Default is 0 (all).
	.PARAMETER ComputerName
		Remote computer to query. If not provided, queries locally.
	.EXAMPLE
		Get-OsQueryDockerContainers

		Returns all Docker containers.
	.EXAMPLE
		Get-OsQueryDockerContainers -IncludeImages

		Returns Docker containers and images.
	#>
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$false)][switch]$IncludeImages,
		[parameter(Mandatory=$false)][int]$Limit = 0,
		[parameter(Mandatory=$false)][string]$ComputerName
	)
	$invokeParams = @{}
	if (![string]::IsNullOrEmpty($ComputerName)) { $invokeParams.ComputerName = $ComputerName }

	$containerTable = 'docker_containers'
	$containerQuery = if ($Limit -gt 0) { "SELECT * FROM $containerTable LIMIT $Limit;" } else { "SELECT * FROM $containerTable;" }
	$results = Invoke-OsQueryTableQuery -Query $containerQuery @invokeParams |
		Select-Object -Property *, @{Name = 'tablename'; Expression = { $containerTable }}

	if ($IncludeImages.IsPresent) {
		$imageTable = 'docker_images'
		$imageQuery = if ($Limit -gt 0) { "SELECT * FROM $imageTable LIMIT $Limit;" } else { "SELECT * FROM $imageTable;" }
		$images = Invoke-OsQueryTableQuery -Query $imageQuery @invokeParams |
			Select-Object -Property *, @{Name = 'tablename'; Expression = { $imageTable }}
		$results = @($results) + @($images)
	}

	$results
}
