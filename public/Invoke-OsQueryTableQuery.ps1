function Invoke-OsQueryTableQuery {
	<#
	.SYNOPSIS
		Executes a query against an osquery table.
	.DESCRIPTION
		This function executes a specified query against an osquery table by calling the osqueryi command-line tool.
	.PARAMETER Query
		The osquery SQL query to execute.
	.PARAMETER TableName
		The name of the osquery table to query. If provided, a default query of "SELECT * FROM TableName;" will be constructed.
	.PARAMETER ComputerName
		The name of the remote computer to execute the query on. If not provided, the query
	.EXAMPLE
		Invoke-OsQueryTableQuery -Query "SELECT * FROM processes;"

		Executes the specified query against the osquery processes table.
	.EXAMPLE
		Invoke-OsQueryTableQuery -TableName "users"
		
		Executes a default query against the osquery users table.
	.NOTES
	#>
	param(
		[parameter(Mandatory=$false)][string]$Query,
		[parameter(Mandatory=$false)][string][Alias('Table')]$TableName,
		[parameter(Mandatory=$false)][string]$ComputerName
	)
	try {
		if ([string]::IsNullOrEmpty($Query) -and -not [string]::IsNullOrEmpty($TableName)) {
			$Query = "SELECT * FROM $TableName;"
		} elseif ([string]::IsNullOrEmpty($Query) -and [string]::IsNullOrEmpty($TableName)) {
			throw "Either Query or TableName parameter must be provided."
		} else {
			if ($Query.EndsWith(';') -eq $false) {
				$Query += ';'
			}
		}
		$params = @{
			ScriptBlock = { param($q) osqueryi --json $q }
			ArgumentList = $Query
		}
		if (![string]::IsNullOrEmpty($ComputerName)) {
			$params.ComputerName = $ComputerName
		}
		Invoke-Command @params | ConvertFrom-Json
	} catch {
		Write-Error "$($_.Exception.Message -join(';'))"
	}
}