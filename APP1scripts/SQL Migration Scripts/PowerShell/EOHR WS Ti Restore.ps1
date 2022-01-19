$SQLScripts ="s3://prod-dependencies-app1-artifacts-bucket/SQL/Scripts"
#$SQLPsModule= "$SQLMigrate/SQLTools/sqlserver.21.1.18245.zip"
#$DBLogins="$SQLScripts/Logins-VIRTAPP1-MDB002.sql"
#$DBMaintPath="$SQLScripts/DBMaint.sql"
#$DBJobSchedulerPath="$SQLScripts/DBJobSched.sql"
#$DBKillUpStatsPath="$SQLScripts/DBKillUpStats.sql"
$SQLAgJob1="$SQLScripts/SQLAgjob-branch2-Titanium-backup.sql"
$SQLAgJob2="$SQLScripts/SQLAgjob-branch2-Titanium-prod-Fix-Missing-CoC.sql"
$SQLAgJob3="$SQLScripts/SQLAgjob-branch2-Titanium-MedicalFieldsRecordsUpdate.sql"
$RowCheck="$SQLScripts/Migration-UserTableRowCountCheck.sql"
$backupfilepath="arn:aws:s3:::dependencies-prod-app1-sqlnativebackup/DB_Dump/branch2/branch2_titanium*"
$secretid="/dependencies-prod-app1/sqldb/creds"
$DBINSTANCE="sqldbaw-app1-prod-001"
$ENDPOINT="sqldbaw-app1-prod-001.ckmzotwi2qcz.ap-southeast-2.rds.amazonaws.com"
$TITANIUMMANAGERSERVERLOCATION = "https://APP1-AWS-WEB-branch2-prod.nswhealth.net"
$TITANIUMWEBSERVICESURL = "https://APP1-AWS-WEB-branch2-prod.nswhealth.net/titanium"
$TITANIUMWEBAPPLICATIONSURL = "https://APP1-AWS-WEB-branch2-prod.nswhealth.net/titanium/web"
$REPORTINGSERVICESSERVERURL = "http://APP1-aws-ssrs-prod.nswhealth.net/ReportServer"
$servername = $ENDPOINT
$username = "Admin"
$DBPassword = (Get-SSMParameter -Name /dependencies-prod-app1/database/password/master -WithDecryption $true).Value
$password = $DBPassword
$DBname = "Titanium_ws_prod"
$ConfigID = "3A1B4DD3-E169-E411-B27A-38EAA73113BB"
#$ADGroup1 = "NSWHEALTH\L-NSWH-Oral Health branch1 SRSS Admin"
#$ADGroup2 = "NSWHEALTH\G-NSWH-Oral Health Vendor Administrators"


#*********************** Downloading and installing powershell module ***********************************
cd\
#mkdir Titanium

Set-Location c:\Titanium
#Write-host "Downloading the SQL Server Powershell module"
#aws s3 cp $SQLPsModule c:\Titanium\sqlserver.21.1.18245.zip
#write-host "Extracting the SQL powershell Module"
#Expand-Archive -LiteralPath c:\Titanium\sqlserver.21.1.18245.zip -DestinationPath C:\Titanium\sqlserver
#Copy-Item  'C:\Titanium\sqlserver' -Destination 'C:\Program Files\WindowsPowerShell\Modules\sqlserver' -Recurse
#write-host "Importing Powershell module for SQL Server"
Import-Module sqlserver -DisableNameChecking    

#******************Creating Titanium Logins and providing access***********************************

$PoshResponse = aws secretsmanager get-secret-value --secret-id $secretid | ConvertFrom-Json
# Parse the response and convert the Secret String JSON into an object
$Creds = $PoshResponse.SecretString | ConvertFrom-Json
$TiWebuser=$Creds.TiWebuser
$TiWebpwd=$Creds.TiWebpwd
$TiDentaluser=$creds.TiDentaluser
$TiDentalpwd=$creds.TiDentalpwd
$Tissrsuser=$creds.Tissrsuser
$Tissrspwd=$creds.Tissrspwd
$SQLAdminGrp = "NSWHEALTH\NSWH-Titanium-Prod-AWS-PROD-Administrators"
$HL7Service = "nswhealth\SRV-SRES-WNSW-HL7"

#******************Logins ****************************************************************************


Write-Host "Creating SQL Logins"

$sql1 = @"
IF NOT EXISTS(SELECT principal_id FROM sys.server_principals WHERE name = '$TiWebuser') BEGIN
    CREATE LOGIN [$TiWebuser] with password = '$TiWebpwd',CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF; 
END

"@
$sql2 = @"
IF NOT EXISTS(SELECT principal_id FROM sys.server_principals WHERE name = '$TiDentaluser') BEGIN
    CREATE LOGIN [$TiDentaluser] with password = '$TiDentalpwd',CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF; 
END

"@
$sql3 = @"
IF NOT EXISTS(SELECT principal_id FROM sys.server_principals WHERE name = '$Tissrsuser') BEGIN
    CREATE LOGIN [$Tissrsuser] with password = '$Tissrspwd',CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF; 
END

"@

$sql4 = @"

IF NOT EXISTS(SELECT principal_id FROM sys.server_principals WHERE name = '$SQLAdminGrp') BEGIN
    CREATE LOGIN [$SQLAdminGrp] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
    ALTER SERVER ROLE [setupadmin] ADD MEMBER [$SQLAdminGrp];
    ALTER SERVER ROLE [processadmin] ADD MEMBER [$SQLAdminGrp];

END

"@

$sql5 = @"

IF NOT EXISTS(SELECT principal_id FROM sys.server_principals WHERE name = '$HL7Service') BEGIN
    CREATE LOGIN [$HL7Service] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
END

"@




#Invoke-Sqlcmd -query $sql1 -serverinstance $servername -Database "master" -username $username -password $password
#Invoke-Sqlcmd -query $sql2 -serverinstance $servername -Database "master" -username $username -password $password
#Invoke-Sqlcmd -query $sql3 -serverinstance $servername -Database "master" -username $username -password $password
#Invoke-Sqlcmd -query $sql4 -serverinstance $servername -Database "master" -username $username -password $password
#Invoke-Sqlcmd -query $sql5 -serverinstance $servername -Database "master" -username $username -password $password

#******************Import Scripted Logins**************************************************************************

#Write-host "Running Logins-VIRTAPP1-MDB002 script"
#aws s3 cp $DBLogins 'c:\Titanium\Logins-VIRTAPP1-MDB002.sql'
#Invoke-Sqlcmd -InputFile 'c:\Titanium\Logins-VIRTAPP1-MDB002.sql' -serverinstance $servername -Database "master" -username $username -password $password 

#********************Restore the backups**************

New-Item C:\Titanium\restore.sql
Set-Content C:\Titanium\restore.sql "exec msdb.dbo.rds_restore_database @restore_db_name='$DBname',@s3_arn_to_restore_from='$backupfilepath';"

write-host "Restoring the Titanium database"

$awsResponse1 = Invoke-Sqlcmd -InputFile 'C:\Titanium\restore.sql' -Serverinstance $servername -Database master -username $username -Password $password

$checkrestoreStatus=$awsResponse1.task_id

$startDate = Get-Date
$timeOutminutes = 45
$retryIntervalSeconds = 30

 do {
     $awsResponse = Invoke-Sqlcmd -ServerInstance $servername -Database master -Username $username -Password $password -Query "exec msdb.dbo.rds_task_status @task_id=$checkrestoreStatus;"
     Write-Host $awsResponse.lifecycle $awsResponse."% complete"

     if ($awsResponse.lifecycle -eq "ERROR"){
       write-host $awsResponse.task_info
     break
      }

       if($awsResponse.lifecycle -eq "SUCCESS") {break}
       start-sleep -seconds $retryIntervalSeconds

 } while ($startDate.AddMinutes($timeOutminutes) -gt (Get-Date))


 #******************Updating Environment/LHD specific values***********************************

 Write-Host "Updating the DB Compatibility level"
 
 $sql1 = @"
 ALTER DATABASE $DBname SET COMPATIBILITY_LEVEL = 130
"@

Invoke-Sqlcmd -query $sql1 -serverinstance $servername -Database "$DBname" -username $username -password $password
write-host "Updating the ConfigData config value to localhost"

$sql1 = @"
update ConfigurationData
set ConfigValue = 'localhost'
where id = '$ConfigID'
"@

Invoke-Sqlcmd -query $sql1 -serverinstance $servername -Database "$DBname" -username $username -password $password

Write-host "Updating Environment values - DATACONFIG"

$sql1 = @"
update DATACONFIG
 set configValue = '$TITANIUMWEBAPPLICATIONSURL'
 where configKey = 'TITANIUM_WEBAPPLICATIONS_URL'
"@
$sql2 = @"
update DATACONFIG
set configValue = '$TITANIUMWEBSERVICESURL'
where configKey = 'TITANIUM_WEBSERVICES_URL'
"@
$sql3 = @"
update DATACONFIG
 set configValue = '$TITANIUMMANAGERSERVERLOCATION'
 where configKey = 'TITANIUM_MANAGER_SERVER_LOCATION'
"@
$sql4 = @"
update DATACONFIG
 set configValue = '$REPORTINGSERVICESSERVERURL'
 where configKey = 'ReportingServicesServerURL'
"@

Invoke-Sqlcmd -query $sql1 -serverinstance $servername -Database "$DBname" -username $username -password $password
Invoke-Sqlcmd -query $sql2 -serverinstance $servername -Database "$DBname" -username $username -password $password
Invoke-Sqlcmd -query $sql3 -serverinstance $servername -Database "$DBname" -username $username -password $password
Invoke-Sqlcmd -query $sql4 -serverinstance $servername -Database "$DBname" -username $username -password $password


#******************Assign DB Permissions***********************************

Write-Host "Assigning DB permissions"

Write-Host "Dropping DB permissions"

$sql1 = @"
USE [$DBname];
GO
IF  EXISTS(SELECT principal_id FROM sys.database_principals WHERE name = '$TiWebuser') BEGIN
    DROP USER [$TiWebuser] 
END

"@
$sql2 = @"
USE [$DBname];
GO
IF  EXISTS(SELECT principal_id FROM sys.database_principals WHERE name = '$TiDentaluser') BEGIN
    DROP USER [$TiDentaluser] 
END

"@

$sql3 = @"
USE [$DBname];
GO
IF  EXISTS(SELECT principal_id FROM sys.database_principals WHERE name = '$SQLAdminGrp') BEGIN
    DROP USER [$SQLAdminGrp]
END

"@

$sql4 = @"
USE [$DBname];
GO
IF  EXISTS(SELECT principal_id FROM sys.database_principals WHERE name = '$Tissrsuser') BEGIN
    DROP USER [$Tissrsuser] 
END

"@

$sql5 = @"
USE [$DBname];
GO
IF  EXISTS(SELECT principal_id FROM sys.database_principals WHERE name = '$HL7Service') BEGIN
    DROP USER [$HL7Service] 
END

"@

Write-Host "Adding DB Permissions"
 
$sql6 = @"
USE [$DBname];
GO
IF NOT EXISTS(SELECT principal_id FROM sys.database_principals WHERE name = '$TiWebuser') BEGIN
    CREATE USER [$TiWebuser] FOR LOGIN [$TiWebuser]
    ALTER ROLE [db_owner] ADD MEMBER [$TiWebuser]
    ALTER ROLE [SparkUsers] ADD MEMBER [$TiWebuser]
END

"@
$sql7 = @"
USE [$DBname];
GO
IF  NOT EXISTS(SELECT principal_id FROM sys.database_principals WHERE name = '$TiDentaluser') BEGIN
    CREATE USER [$TiDentaluser] FOR LOGIN [$TiDentaluser]
    ALTER ROLE [db_owner] ADD MEMBER [$TiDentaluser]
    ALTER ROLE [SparkUsers] ADD MEMBER [$TiDentaluser]
END

"@

$sql8 = @"
USE [$DBname];
GO
IF NOT EXISTS(SELECT principal_id FROM sys.database_principals WHERE name = '$SQLAdminGrp') BEGIN
    CREATE USER [$SQLAdminGrp] FOR LOGIN [$SQLAdminGrp]
    ALTER ROLE [db_owner] ADD MEMBER [$SQLAdminGrp]
END

"@

$sql9 = @"
USE [$DBname];
GO
IF NOT EXISTS(SELECT principal_id FROM sys.database_principals WHERE name = '$Tissrsuser') BEGIN
    CREATE USER [$Tissrsuser] FOR LOGIN [$Tissrsuser]
    ALTER ROLE [db_datareader] ADD MEMBER [$Tissrsuser]
    GRANT EXECUTE TO [$Tissrsuser]
END

"@

$sql10 = @"
USE [$DBname];
GO
IF NOT EXISTS(SELECT principal_id FROM sys.database_principals WHERE name = '$HL7Service') BEGIN
    CREATE USER [$HL7Service] FOR LOGIN [$HL7Service]
    ALTER ROLE [db_datawriter] ADD MEMBER [$HL7Service]
END

"@

Invoke-Sqlcmd -query $sql1 -serverinstance $servername -Database "master" -username $username -password $password
Invoke-Sqlcmd -query $sql2 -serverinstance $servername -Database "master" -username $username -password $password
Invoke-Sqlcmd -query $sql3 -serverinstance $servername -Database "master" -username $username -password $password
Invoke-Sqlcmd -query $sql4 -serverinstance $servername -Database "master" -username $username -password $password
Invoke-Sqlcmd -query $sql5 -serverinstance $servername -Database "master" -username $username -password $password
Invoke-Sqlcmd -query $sql6 -serverinstance $servername -Database "master" -username $username -password $password
Invoke-Sqlcmd -query $sql7 -serverinstance $servername -Database "master" -username $username -password $password
Invoke-Sqlcmd -query $sql8 -serverinstance $servername -Database "master" -username $username -password $password
Invoke-Sqlcmd -query $sql9 -serverinstance $servername -Database "master" -username $username -password $password
Invoke-Sqlcmd -query $sql10 -serverinstance $servername -Database "master" -username $username -password $password

#************************Creating the SQL Agent jobs**********************************************************

#Write-host "Running DBMaint script"
#aws s3 cp $DBMaintPath 'c:\Titanium\DBMaint.sql'
#Invoke-Sqlcmd -InputFile 'c:\Titanium\DBMaint.sql' -serverinstance $servername -Database "msdb" -username $username -password $password 

#Write-host "Running DBKillUpStats script"
#aws s3 cp $DBKillUpStatsPath 'c:\Titanium\DBKillUpStats.sql'
#Invoke-Sqlcmd -InputFile 'c:\Titanium\DBKillUpStats.sql' -serverinstance $servername -Database "msdb" -username $username -password $password 

#Write-host "Running DBjobs scheduler script"
#aws s3 cp $DBJobSchedulerPath 'c:\Titanium\DBJobSched.sql'
#Invoke-Sqlcmd -InputFile 'c:\Titanium\DBJobSched.sql' -serverinstance $servername -Database "msdb" -username $username -password $password 

#Write-host "Running SAgJob-branch2-Backup script"
#aws s3 cp $SQLAgJob1 'c:\Titanium\SQLAgjob-branch2-Titanium-backup.sql'
#Invoke-Sqlcmd -InputFile 'c:\Titanium\SQLAgjob-branch2-Titanium-backup.sql' -serverinstance $servername -Database "msdb" -username $username -password $password 

#Write-host "Running SAgJob-FixMissingCoC script"
#aws s3 cp $SQLAgJob2 'c:\Titanium\SQLAgjob-branch2-Titanium-prod-Fix-Missing-CoC.sql'
#Invoke-Sqlcmd -InputFile 'c:\Titanium\SQLAgjob-branch2-Titanium-prod-Fix-Missing-CoC.sql' -serverinstance $servername -Database "msdb" -username $username -password $password 

#Write-host "Running SAgJob-MedicalHistoryRecordsUpdate-WS script"
#aws s3 cp $SQLAgJob3 'c:\Titanium\SQLAgjob-branch2-Titanium-MedicalFieldsRecordsUpdate.sql'
#Invoke-Sqlcmd -InputFile 'c:\Titanium\SQLAgjob-branch2-Titanium-MedicalFieldsRecordsUpdate.sql' -serverinstance $servername -Database "msdb" -username $username -password $password 

Write-host "Running Migration-UserTableRowCountCheck script"
aws s3 cp $RowCheck 'c:\Titanium\Migration-UserTableRowCountCheck.sql'
Invoke-Sqlcmd -InputFile 'c:\Titanium\Migration-UserTableRowCountCheck.sql' -serverinstance $servername -Database "$DBname" -username $username -password $password | Export-Csv -NoTypeInformation -Path "C:\Titanium\UserTableRowCount.csv" -Encoding UTF8

Write-host "Titanium DB migrated successfully"