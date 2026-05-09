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
	[CmdletBinding()]
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
		} elseif (-not $Query.EndsWith(';')) {
			$Query += ';'
		}
		$bin = Get-OsQueryBinaryPath
		if (-not $bin -and [string]::IsNullOrEmpty($ComputerName)) {
			throw "osqueryi not found in PATH. Ensure osquery is installed and accessible."
		}
		$params = @{
			ScriptBlock  = {
				param($q, $bin)
				& $bin --json $q
			}
			ArgumentList = $Query, $bin
		}
		if (![string]::IsNullOrEmpty($ComputerName)) {
			$params.ComputerName = $ComputerName
		}
		Invoke-Command @params | ConvertFrom-Json
	} catch {
		Write-Error $_.Exception.Message
	}
}
