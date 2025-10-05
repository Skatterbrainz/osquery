function Get-OsQuerySchema {
	<#
	.SYNOPSIS
		Retrieves the osquery schema information.
	.DESCRIPTION
		This function retrieves the osquery schema information by calling the Get-OsQuerySchema function from the osquery module.
	.EXAMPLE
		Get-OsQuerySchema
	.NOTES
	#>
	param(
		[parameter(Mandatory=$false)]
		[ValidateSet('config','config_parser','database','distributed','enroll','event_publisher','event_subscriber','logger','numeric_monitoring','sql','table')]
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