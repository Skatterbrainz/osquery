function Get-OsQuerySchema {
	<#
	.SYNOPSIS
		Retrieves the osquery schema information.
	.DESCRIPTION
		This function retrieves the osquery schema information by calling the Get-OsQuerySchema function from the osquery module.
	.PARAMETER Type
		The type of schema to retrieve. Valid values are 'config', 'config_parser', 'database', 'distributed', 'enroll', 'event_publisher', 'event_subscriber', '
		'logger', 'numeric_monitoring', 'sql', and 'table'. Default is 'table'.
	.PARAMETER ComputerName
		The name of the remote computer to execute the query on. If not provided, the query
	.EXAMPLE
		Get-OsQuerySchema
		Retrieves the osquery table schema information.
	.EXAMPLE
		Get-OsQuerySchema -Type 'table' -ComputerName 'RemotePC'
		Retrieves the osquery table schema information from the remote computer named RemotePC.
	.NOTES
	#>
	param(
		[parameter(Mandatory=$false)]
		[ValidateSet('config','config_parser','database','distributed','enroll','event_publisher','event_subscriber','logger','numeric_monitoring','sql','table')]
		[Alias('RegistryType')]
		[string]$Type = 'table',
		[parameter(Mandatory=$false)][string]$ComputerName
	)
	$params = @{
		ScriptBlock = { osqueryi --json "SELECT name FROM osquery_registry WHERE registry='$($Type)';" }
	}
	if (![string]::IsNullOrEmpty($ComputerName)) {
		$params.ComputerName = $ComputerName
	}
	Invoke-Command @params | ConvertFrom-Json
}