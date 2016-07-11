<#
.SYNOPSIS
  Get and Install Azure SQL Database - Elastic Database Jobs
.DESCRIPTION
  After login into an Azure account it will download de packages (1) and install them (2)
  You will be prompted for elastic jobs user credentials   
#>

########################
# Parameters
########################

$FolderName = "ElasticDatabaseJobs"

#It is not recommended to change this value, portal will not detect installation if changed
$resourceGroupgName = "__ElasticDatabaseJob" 

$resourceGroupLocation = "westeurope"

#numbers lower-case letters only, unique worldwide
$serverAndStorageName = "vbtelasticdatabasejob101"


########################
# Step 0 : Login
########################

Login-AzureRmAccount


########################
# Step 1 : Download bits
########################

#Uncomment this if you always want to delete existing folder:
if(Test-Path -Path $FolderName ){
    Remove-Item $FolderName -Recurse
}

if(!(Test-Path -Path $FolderName )){
    New-Item $FolderName -type directory
}

cd $FolderName

#Download nuget.exe (nuget package manager)
$url = "https://nuget.org/nuget.exe"
$output = ".\nuget.exe"
$start_time = Get-Date
Invoke-WebRequest -Uri $url -OutFile $output
Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"

#Get nuget package 
.\nuget.exe install Microsoft.Azure.SqlDatabase.Jobs -prerelease

#Install Elastic Jobs
cd .\Microsoft.Azure.SqlDatabase.Jobs.*
cd tools
Unblock-File .\InstallElasticDatabaseJobs.ps1

########################
#Step 2 : Install
########################

.\InstallElasticDatabaseJobs.ps1 `
-ResourceGroupName $resourceGroupgName `
-ResourceGroupLocation $resourceGroupLocation `
-ServiceName $serverAndStorageName `
-NoPrompt

#Uninstall
#.\UninstallElasticDatabaseJobs.ps1 -ResourceGroupName $rgName