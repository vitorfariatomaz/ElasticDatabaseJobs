<#
.SYNOPSIS
  Uninstall Azure SQL Database - Elastic Database Jobs
#>

########################
# Parameters
########################

$homeDir = [Environment]::GetFolderPath("UserProfile")
cd $homeDir
$FolderName = "ElasticDatabaseJobs"

#It is not recommended to change this value, portal will not detect installation if changed
$resourceGroupgName = "__ElasticDatabaseJob" 


########################
# Step 0 : Login
########################

Login-AzureRmAccount

########################
# Step 1 : Uninstall
########################

cd $FolderName
cd .\Microsoft.Azure.SqlDatabase.Jobs.*
cd tools
.\UninstallElasticDatabaseJobs.ps1 -ResourceGroupName $resourceGroupgName


<# Delete the folder
cd $homeDir
Remove-Item $FolderName -Recurse
#>