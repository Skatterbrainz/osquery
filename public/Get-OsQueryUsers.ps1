function Get-OsQueryUsers {
	<#
	.SYNOPSIS
	Retrieves a list of users from the osquery database.
	
	.DESCRIPTION
	This function queries the 'users' table in the osquery database to retrieve user information.
	
	.PARAMETER Limit
	Specifies the maximum number of user records to return. Default is 0.
	
	.EXAMPLE
	Get-OsQueryUsers

	Retrieves all user records from the osquery database.

	.EXAMPLE
	Get-OsQueryUsers -Limit 50

	Retrieves up to 50 user records from the osquery database.
	
	#>
	
	[CmdletBinding()]
	param (
		[parameter(Mandatory=$false)][int]$Limit = 0,
		[parameter(Mandatory=$false)][string]$ComputerName
	)
	
	$tablename = "users"
	
	if ($Limit -gt 0) {
		$query = "SELECT * FROM $tablename LIMIT $Limit;"
	} else {
		$query = "SELECT * FROM $tablename;"
	}
	$invokeParams = @{ Query = $query }
	if (![string]::IsNullOrEmpty($ComputerName)) { $invokeParams.ComputerName = $ComputerName }
	Invoke-OsQueryTableQuery @invokeParams | Select-Object -Property *, @{Name = "tablename"; Expression = { $tablename }}
}