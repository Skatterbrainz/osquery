function Get-OsQueryTableSample {
	<#
	.SYNOPSIS
	Retrieves a sample query for a specified osquery table.

	.DESCRIPTION
	The Get-OsQueryTableSample function takes the name of an osquery table as input and returns a sample SQL query that can be used to query that table.

	.PARAMETER TableName
	The name of the osquery table for which to retrieve a sample query.

	.PARAMETER Limit
	(Optional) The number of rows to limit the query results to. Default is 10.

	.EXAMPLE
	Get-OsQueryTableSample -TableName "processes"

	This command retrieves a sample query for the "processes" table.

	.EXAMPLE
	Get-OsQueryTableSample -TableName "users" -Limit 5

	This command retrieves a sample query for the "users" table, limiting the results to 5 rows.

	.NOTES
	For Windows platforms, an interactive grid view is provided for table selection.
	For non-Windows platforms, the function checks for the presence of 'helium' or 'Microsoft.PowerShell.ConsoleGuiTools' modules to provide a grid view selection.
	#>
	[CmdletBinding()]
	param (
		[Parameter(Mandatory = $false)][string]$TableName,
		[Parameter(Mandatory = $false)][int]$Limit = 10
	)
	$tables = Get-OsQuerySchema
	if ($tables.Count -eq 0) {
		Write-Error "No osquery tables found. Ensure osquery is installed and accessible."
		return
	}
	if ([string]::IsNullOrEmpty($TableName)) {
		if ($IsWindows) {
			$table = $tables | Out-GridView -Title "Select a Table to Query" -OutputMode Single
		} else {
			if (Get-Module -Name helium -ListAvailable) {
				$table = Out-GridSelect -InputObject $tables -Title "Select a Table to Query"
			} elseif (Get-Module -Name Microsoft.PowerShell.ConsoleGuiTools -ListAvailable) {
				$table = $tables | Out-ConsoleGridView -Title "Select a Table to Query" -OutputMode Single
			} else {
				Write-Warning "For an enhanced selection experience, consider installing the 'helium' or 'Microsoft.PowerShell.ConsoleGuiTools' module."
			}
		}
	} else {
		$table = $tables | Where-Object { $_.name -eq $TableName }
		if (-not $table) {
			Write-Error "Table '$TableName' not found in osquery schema."
			return
		}
	}
	if ($table) {
		$query = "SELECT * FROM $($table.name) LIMIT $Limit;"
		Write-Output $query
		Invoke-OsQueryTableQuery -Query $query | Select-Object -Property *, @{Name = "tablename"; Expression = { $table.name }}
	} else {
		Write-Error "No table selected."
	}
}