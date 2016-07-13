<#
.SYNOPSIS
 Install AzureSQLMaintenance scripts and schedule a daily job for them  

.DESCRIPTION
 This script will create and run 2 jobs
 (1) Install AzureSQLMaintenance scripts
 (2) Execute AzureSQLMaintenance 
 and add a schedule in order to daily run job (2)
#>
########################
# Parameters
########################

## ElasticJobs Parameters
$serverAndStorageName = "vbtelasticdatabasejob101"

## Target Server Parameters 
$databaseServerResourceGroupName = "vbttest1"
$databaseServerName = "vbttest1"

########################################################
# Step 0 : Login
########################################################

Login-AzureRmAccount

########################################################
# Step 1 : Create Collection 
########################################################

#This will ask you for ElasticJobs credentials
Use-AzureSqlJobConnection -DatabaseName $serverAndStorageName -ServerName $serverAndStorageName

$customCollectionName = "DailyMaintenanceCollection"
New-AzureSqlJobTarget -CustomCollectionName $customCollectionName

## Check the result
#Get-AzureSqlJobTarget -CustomCollectionName $customCollectionName 

########################################################
# Step 2 : Add targets 
########################################################

## Add all databases from a server

$databases = Get-AzureRmSqlDatabase -ResourceGroupName $databaseServerResourceGroupName -ServerName $databaseServerName

foreach($db in $databases) 
{
    if($db.DatabaseName -ne 'master')
    {
        $target1 = New-AzureSqlJobTarget -DatabaseName $db.DatabaseName -ServerName $db.ServerName 
        Add-AzureSqlJobChildTarget -CustomCollectionName $customCollectionName -TargetId $target1.TargetId
    }
}

## Check the results
# Get-AzureSqlJobChildTarget -CustomCollectionName $customCollectionName

## Add single databases from a server
#$databaseServerName = "vbttest1"
#$databaseName = "vbttest1"
#$target1 = New-AzureSqlJobTarget -DatabaseName $databaseName -ServerName $databaseServerName 
#Add-AzureSqlJobChildTarget -CustomCollectionName $customCollectionName -TargetId $target1.TargetId


########################################################
# Step 3 : Job credentials
########################################################

#This will ask you for target server credentials
$credentialName = "jobCredential"
$databaseCredential = Get-Credential
$credential = New-AzureSqlJobCredential -Credential $databaseCredential -CredentialName $credentialName
Write-Output $credential


########################################################
# Step 3 : Create Install/Update maintenance scripts job
########################################################

$AzureSQLMaintenance_Script_URI = "https://msdnshared.blob.core.windows.net/media/2016/07/AzureSQLMaintenance.txt"

$installScripts_ScriptName = "Install_AzureSQLMaintenance_Script"
$installScripts_CommandText = (Invoke-webrequest -URI $AzureSQLMaintenance_Script_URI).Content

$installScripts_JobContent = New-AzureSqlJobContent -ContentName $installScripts_ScriptName -CommandText $installScripts_CommandText
Write-Output $installScripts_JobContent

$installScripts_JobName = "Install_AzureSQLMaintenance_Job"
$target = Get-AzureSqlJobTarget -CustomCollectionName $customCollectionName

$job = New-AzureSqlJob -JobName $installScripts_JobName -CredentialName $credentialName -ContentName $installScripts_ScriptName -TargetId $target.TargetId
Write-Output $job

#######################################################
# Step 3.1 : Run Install/Update maintenance scripts job
#######################################################

$jobExecution = Start-AzureSqlJobExecution -JobName $installScripts_JobName 
Write-Output $jobExecution

## Check execution
#Get-AzureSqlJobExecution -TargetId $target.TargetId –IncludeInactive


########################################################
# Step 4 : Create maintenance scripts job
########################################################

$scriptName = "AzureSQLMaintenance"
$scriptCommandText = "EXEC AzureSQLMaintenance 'all'
GO"

$script = New-AzureSqlJobContent -ContentName $scriptName -CommandText $scriptCommandText
Write-Output $script

$jobName = "AzureSQLMaintenanceJob"
$target = Get-AzureSqlJobTarget -CustomCollectionName $customCollectionName
$job = New-AzureSqlJob -JobName $jobName -CredentialName $credentialName -ContentName $scriptName -TargetId $target.TargetId
Write-Output $job


########################################################
# Step 4.1 : Run maintenance scripts job
########################################################

$jobExecution = Start-AzureSqlJobExecution -JobName $jobName 
Write-Output $jobExecution

## Check execution
#Get-AzureSqlJobExecution -TargetId $target.TargetId –IncludeInactive


########################################################
# Step 5 : Schedule maintenance scripts job
########################################################

#Note: there is no scheduler for updating the maintenance scripts, you should start the job manually if needed

$scheduleName = "Every day at 1 AM"
$startTimeUTC = (get-date).Date.AddDays(1).AddHours(1).ToUniversalTime()
$schedule = New-AzureSqlJobSchedule -DayInterval 1 -ScheduleName $scheduleName -StartTime $startTimeUTC 
Write-Output $schedule

$jobTrigger = New-AzureSqlJobTrigger -ScheduleName $scheduleName –JobName $jobName 
Write-Output $jobTrigger

## Check results
#Get-AzureSqlJobTrigger

## Remove Schedule
#Remove-AzureSqlJobTrigger -ScheduleName $scheduleName -JobName $jobName