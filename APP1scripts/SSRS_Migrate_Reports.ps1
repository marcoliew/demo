<#################################SSRS Database Migration Script########################################################
Author: Greg Thompson 29/10/21
To be used to Migrate reports by perfroming a restore of Reportserver databases.

Main-Steps
-----------

1. Download Source Content
2. Restore Databases
3. Set SSRS to use the restored database (Set-RsDatabase)
4. Remove Encryption key data 
5. Apply Encryption key
6. Set email details (SMTP)
7. Assign Security

Pre-Requisites include
------------------------

1. Source Server ReportServer.bak and ReportServerTempDB.bak containing relevant reports and subscriptions - Uploaded to S3 Location
2. Encryption key backed up from source server and password (Must exist in Secret manager location) - Uploaded to S3 Location
3. PS Modules ReportingServices and SQLserver- Uploaded to S3 location

Post-execution Steps
--------------------

1. Check email (SMTP) settings have been applied
2. Launch http://servername/Reports and test login - Should be able to browse migrated folders
3. Check and Update Datasources to connect to relevant On-Prem / RDS SQL Server databases 
   (If Datasource server connection details are blank - Encryption key restore has failed)
4. Copy backed up new Encryption key somewhere safe for retrieval
5. Disable SQl Agent Jobs (Auto-Created by SSRS) - Pending testing before being enabled! 
6. Update rsreportserver.config with custom settings (Add .Txt extension etc..)
7. Setup https:// URLs with certificate for Reports/ReportServer

To Do:-
-------

1. Automate DataSource Updates??

#>

#Servers and Creds
$Servername = "$env:COMPUTERNAME"
$secretid="APP1ssrs"
$PoshResponse = aws secretsmanager get-secret-value --secret-id $secretid | ConvertFrom-Json
$Creds = $PoshResponse.SecretString | ConvertFrom-Json
$username = $Creds.username
$EncKeyPwd = $Creds.ssrsenc
$password = $Creds.sapassword

#S3 Source File Locations

$SQLRSModule= "s3://nswh-provider-ap-southeast-2-inf-497427545767/reportingservicestools.zip"
$SQLPsModule= "s3://nswh-provider-ap-southeast-2-inf-497427545767/sqlserver.21.1.18245.zip"
$ReportServerbak="s3://sqlnativebackups/ReportServer.bak"
$ReportServerTempDBbak="s3://sqlnativebackups/ReportServerTempDB.bak"
$RSEncryptionKey="s3://sqlnativebackups/RSenc.snk"

#SSRS variables

$reportServerUri = "http://$Servername/ReportServer/ReportService2019.asmx?wsdl"
$ReportServerVersion = "15"
$ADSSRSAdminRoleGroup1 = "NSWHEALTH\NSWH-Titanium86-NonProd-AWS-TEST-Administrators"
$ADSSRSAdminRoleGroup2 = "NSWHEALTH\app1-poc-NSWH-aws-Administrators"

$Instance = "SSRS"
$smtpserver = "smtp.nswhealth.net"
$Instance = "SSRS"
$ReportServerVersion = "15"
$SenderAddress = "EHNSW-TitaniumReport@health.nsw.gov.au"
$UploadSummary = "s3://nswh-provider-ap-southeast-2-inf-497427545767/SSRS/SSRS_Config_Summary.txt"
$RSEncNewKey="s3://sqlnativebackups/RSencNew.snk"

#Initial Setup for script Execution

cd\
mkdir Titanium\SSRS

Set-Location c:\Titanium\SSRS

# Start Logging

$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path C:\Titanium\SSRS\SSRSConfig_Summary.txt -append
write-host "setting execution policy"
Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Cryptography\Protect\Providers\df9d8cd0-1501-11d1-8c7a-00c04fc297eb" | New-ItemProperty -Name 'ProtectionPolicy' -Value '1' -PropertyType DWORD
write-host "Downloading the SQL Powershell module"
aws s3 cp $SQLPSModule c:\Titanium\SSRS\sqlserver.21.1.18245.zip
write-host "Extracting The SQL Powershell module"
Expand-Archive -LiteralPath c:\Titanium\SSRS\sqlserver.21.1.18245.zip -DestinationPath C:\Titanium\SSRS\sqlserver
Copy-Item  'C:\Titanium\SSRS\sqlserver' -Destination 'C:\Program Files\WindowsPowerShell\Modules\sqlserver' -Recurse
write-host "Downloading the Reporting Services Powershell module"
aws s3 cp $SQLRSModule c:\Titanium\SSRS\reportingservicestools.zip
write-host "Extracting The Reporting Services Powershell module"
Expand-Archive -LiteralPath c:\Titanium\SSRS\reportingservicestools.zip -DestinationPath C:\Titanium\SSRS\reportingservicestools
Copy-Item  'C:\Titanium\SSRS\reportingservicestools' -Destination 'C:\Program Files\WindowsPowerShell\Modules\reportingservicestools' -Recurse
aws s3 cp $ReportServerbak c:\Titanium\SSRS\ReportServer.bak 
aws s3 cp $ReportServerTempDBbak c:\Titanium\SSRS\ReportServerTempDB.bak 
aws s3 cp $RSEncryptionKey c:\Titanium\SSRS\RSenc.snk

# Stop SSRS Service while ReportServer databases are restored

write-host " Stopping SSRS service"

Get-Service 'SQLServerReportingServices' | Stop-Service;

# Connect to SQL and Perform Reportserver DB restores

Import-Module sqlserver -DisableNameChecking 


Write-host "Restoring the ReportServer databases" 

$sql1 = @"
ALTER DATABASE [ReportServer] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
RESTORE DATABASE [ReportServer] FROM  DISK = N'C:\Titanium\SSRS\ReportServer.bak' WITH  FILE = 1,  MOVE N'ReportServer' TO N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\ReportServer.mdf',  MOVE N'ReportServer_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\ReportServer_log.ldf',  NOUNLOAD,  REPLACE,  STATS = 5
ALTER DATABASE [ReportServer] SET MULTI_USER

GO
"@
$sql2 = @"
ALTER DATABASE [ReportServerTempDB] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
RESTORE DATABASE [ReportServerTempDB] FROM  DISK = N'C:\Titanium\SSRS\ReportServerTempDB.bak' WITH  FILE = 1,  MOVE N'ReportServerTempDB' TO N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\ReportServerTempDB.mdf',  MOVE N'ReportServerTempDB_log' TO N'C:\Program Files\Microsoft SQL Server\MSSQL15.MSSQLSERVER\MSSQL\DATA\ReportServerTempDB_log.ldf',  NOUNLOAD,  REPLACE,  STATS = 5
ALTER DATABASE [ReportServerTempDB] SET MULTI_USER

GO

"@  

Invoke-Sqlcmd -query $sql1 -serverinstance $servername -Database "master" -username $username -password $password
Invoke-Sqlcmd -query $sql2 -serverinstance $servername -Database "master" -username $username -password $password

Import-Module -Name ReportingServicesTools


# Start SSRS Service 

write-host " Starting SSRS service"

Get-Service 'SQLServerReportingServices' | Start-Service;

Write-host "Setting up the restored database"

Set-RsDatabase -DatabaseServerName $servername -Name ReportServer -ReportServerInstance $Instance -ReportServerVersion $ReportServerVersion -IsExistingDatabase -DatabaseCredentialType ServiceAccount -Confirm:$false


$sql1 = @"
DELETE FROM dbo.Keys
WHERE MachineName Not In ('$servername')
GO
"@
$sql2=  @"
IF NOT EXISTS(SELECT * FROM dbo.Keys WHERE InstallationID = '00000000-0000-0000-0000-000000000000') BEGIN
    insert into dbo.keys ([MachineName],[InstallationID],[InstanceName],[Client],[PublicKey],[SymmetricKey])  values (NULL,'00000000-0000-0000-0000-000000000000',NULL,-1,NULL,NULL)
END

"@


Invoke-Sqlcmd -query $sql1 -serverinstance $servername -Database "ReportServer" -username $username -password $password
Invoke-Sqlcmd -query $sql2 -serverinstance $servername -Database "ReportServer" -username $username -password $password

Write-Host "Restoring the Encryption Keys"

Restore-RSEncryptionKey -ReportServerInstance $Instance -ReportServerVersion $ReportServerVersion -Password $EncKeyPwd -KeyPath 'c:\Titanium\SSRS\RSenc.snk'


#Initialize-Rs -ReportServerInstance $Instance -ReportServerVersion $ReportServerVersion 

# Configure email settings for Report Server (SMTP)

Write-host "Applying email configuration"

Set-RsEmailSettings -ReportServerInstance $Instance -ReportServerVersion $ReportServerVersion -Authentication None -SmtpServer $smtpserver -SenderAddress $SenderAddress
           
Write-host "Email Settings Applied"

# Apply SSRS Server Permissions

Write-host "Applying ReportServer Admin Group permissions"

Grant-RsSystemRole -ReportServerUri $reportServerUri -Identity $ADSSRSAdminRoleGroup1 -RoleName 'System Administrator'
Grant-RsSystemRole -ReportServerUri $reportServerUri -Identity $ADSSRSAdminRoleGroup2 -RoleName 'System Administrator'


#$ADContentMgrRoleGroups | ForEach-Object {Grant-RsCatalogItemRole -ReportServerUri $reportServerUri -Identity $_ -RoleName 'Content Manager'  -Path "/"}

#Write-Host "Security Group permissions Applied"

Write-host "Restart SSRS Service"

Get-Service 'SQLServerReportingServices' | Restart-Service;

Write-Host "Backup the encryption key"

Backup-RSEncryptionKey -ReportServerInstance $Instance -ReportServerVersion $ReportServerVersion -Password $EncKeyPwd -KeyPath 'c:\Titanium\SSRS\RSencNew.snk'

Write-Host "End of Script"

Stop-Transcript

aws s3 cp 'C:\Titanium\SSRS\SSRSConfig_Summary.txt' $UploadSummary
aws s3 cp 'C:\Titanium\SSRS\RSencNew.snk' $RSEncNewKey


