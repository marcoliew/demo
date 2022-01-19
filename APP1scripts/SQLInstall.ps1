$SQLServerInstallPath = "s3://$env:bucketname/SQL/Standard - ServerCAL.zip"
$SQLRSInstallPath = "s3://$env:bucketname/SQL/SQLServerReportingServices.exe"
$SQLPsModule = "s3://$env:bucketname/SQL/sqlserver.21.1.18245.zip"
$SQLLogfilePath = "s3://$env:bucketname/SQL/Logs/Summary.txt"
$SQLRSLogfilePath = "s3://$env:bucketname/SQL/Logs/ssrs_install.txt"
$artifactBucket = $env:bucketname 
$CWagent="s3://$env:bucketname/amazon-cloudwatch-agent.msi"

cd\
mkdir Titanium

Set-Location c:\Titanium
write-host "setting execution policy"

Write-host "Starting SQL Server installation"
Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Cryptography\Protect\Providers\df9d8cd0-1501-11d1-8c7a-00c04fc297eb" | New-ItemProperty -Name 'ProtectionPolicy' -Value '1' -PropertyType DWORD
$env_tag = $env:environment
$SSMParamUser = "/dependencies-$env_tag-app1/ssrs_db/password/master"
$DBPassword = aws ssm get-parameter --name $SSMParamUser --region=ap-southeast-2 --with-decryption --output text --query Parameter.Value

$secretid=$env:secret_id
#$PoshResponse = aws secretsmanager get-secret-value --secret-id /dependencies-train-app1/sqldb/creds | ConvertFrom-Json
$PoshResponse = aws secretsmanager get-secret-value --secret-id $secretid | ConvertFrom-Json

# Parse the response and convert the Secret String JSON into an object
$Creds = $PoshResponse.SecretString | ConvertFrom-Json

$SSRSPID=$Creds.PID
#$ServerName='localhost'
Write-host "Downloading SQL Server installation media files"
aws s3 cp $SQLServerInstallPath 'c:\Titanium\Standard - ServerCAL.zip'
Expand-Archive -LiteralPath 'c:\Titanium\Standard - ServerCAL.zip' -DestinationPath 'C:\Titanium\'
#aws s3 cp 's3://Titanium/Mirth/MSSQL.ini' 'c:\Titanium\MSSQL.ini'
Set-Location "C:\Titanium\Standard - ServerCAL\"


#Start-Process -Wait -FilePath "C:\Titanium\Standard - ServerCAL\setup.exe" -ArgumentList ("/q /IACCEPTSQLSERVERLICENSETERMS /ACTION=Install /FEATURES=SQL /UpdateEnabled=False /INSTANCENAME=MSSQLSERVER /SECURITYMODE=SQL /SAPWD="$password" /SQLSVCACCOUNT="NT Service\MSSQLSERVER" /SQLSYSADMINACCOUNTS=".\Administrator" /AGTSVCACCOUNT="NT Service\SQLSERVERAGENT"
Start-Process -Wait -FilePath 'C:\Titanium\Standard - ServerCAL\setup.exe'  -ArgumentList ("/q /IACCEPTSQLSERVERLICENSETERMS /ACTION=Install /FEATURES=SQLENGINE /UpdateEnabled=False /INSTANCENAME=MSSQLSERVER /SECURITYMODE=SQL /SAPWD='$DBPassword' /SQLSYSADMINACCOUNTS=BUILTIN\ADMINISTRATORS") -Verb RunAs -PassThru
aws s3 cp 'C:\Program Files\Microsoft SQL Server\150\Setup Bootstrap\Log\Summary.txt' $SQLLogfilePath

Write-host "Downloading SQL Reporting Services media files"
aws s3 cp $SQLRSInstallPath 'c:\Titanium\SQLServerReportingServices.exe'
Start-Process -Wait -FilePath 'c:\Titanium\SQLServerReportingServices.exe' -ArgumentList ("/IAcceptLicenseTerms /norestart /PID=$SSRSPID /log c:\titanium\ssrs_install.txt /quiet") -Verb RunAs -PassThru
aws s3 cp 'c:\titanium\ssrs_install.txt' $SQLRSLogfilePath
Set-Location c:\Titanium
write-host "Downloading the SQL Server Powershell module"
aws s3 cp $SQLPsModule c:\Titanium\sqlserver.21.1.18245.zip
write-host "Extracting the SQL powershell Module"
Expand-Archive -LiteralPath c:\Titanium\sqlserver.21.1.18245.zip -DestinationPath C:\Titanium\sqlserver
Copy-Item  'C:\Titanium\sqlserver' -Destination 'C:\Program Files\WindowsPowerShell\Modules\sqlserver' -Recurse


#install ARS
$ARSinstallationPath= "s3://$artifactBucket/Active_Roles_7.4.3.zip"
Write-host " ARS installation"
aws s3 cp $ARSinstallationPath c:\temp\app1\Active_Roles_7.4.3.zip
Expand-Archive -LiteralPath c:\temp\app1\Active_Roles_7.4.3.zip -DestinationPath C:\temp\app1\ -force
Write-host "Downloaded ARS setup file "
Start-Process -Wait -FilePath 'C:\temp\app1\Active_Roles_7.4.3\ActiveRoles.exe' -ArgumentList '/quiet','/install','/ADDLOCAL=Tool','/IAcceptActiveRolesLicenseTerms' -Verb RunAs -PassThru

# CW part
$CWagent="s3://$artifactBucket/amazon-cloudwatch-agent.msi"
Write-host "Cloudwatch agent installation"
aws s3 cp $CWagent 'c:\temp\app1\amazon-cloudwatch-agent.msi'
Start-Process msiexec.exe -Wait -ArgumentList '/quiet /i c:\temp\app1\amazon-cloudwatch-agent.msi' -Verb RunAs -PassThru