<powershell>
$SSMSServerInstallPath= "s3://dependencies-prod-app1-sqlnativebackup/SQLMigrate/SQLTools/SSMS-Setup-ENU.exe"
$SQLRSModule= "s3://dependencies-prod-app1-sqlnativebackup/SSRS/ReportingServicesTools.zip"
$SQLPsModule="s3://dependencies-prod-app1-sqlnativebackup/SQLMigrate/SQLTools/sqlserver.21.1.18245.zip"
#$LogfilePath="s3://dependencies-prod-app1-sqlnativebackup/SQLMigrate/SQLTools/Summary.txt"


cd\
mkdir Titanium

Set-Location c:\Titanium
write-host "setting execution policy"

Write-host "Starting SQL Server installation"
Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Cryptography\Protect\Providers\df9d8cd0-1501-11d1-8c7a-00c04fc297eb" | New-ItemProperty -Name 'ProtectionPolicy' -Value '1' -PropertyType DWORD

Write-host "Downloading installation media files"
aws s3 cp $SSMSServerInstallPath 'c:\Titanium\SSMS-Setup-ENU.exe'
aws s3 cp $SQLPsModule c:\Titanium\sqlserver.21.1.18245.zip
aws s3 cp $SQLRSModule c:\Titanium\reportingservicestools.zip
write-host "Extracting the SQL powershell Module"
Expand-Archive -LiteralPath c:\Titanium\sqlserver.21.1.18245.zip -DestinationPath C:\Titanium\sqlserver
Copy-Item  'C:\Titanium\sqlserver' -Destination 'C:\Program Files\WindowsPowerShell\Modules\sqlserver' -Recurse
write-host "Extracting The Reporting Services Powershell module"
Expand-Archive -LiteralPath c:\Titanium\reportingservicestools.zip -DestinationPath C:\Titanium\reportingservicestools
Copy-Item  'C:\Titanium\reportingservicestools' -Destination 'C:\Program Files\WindowsPowerShell\Modules\reportingservicestools' -Recurse
Set-Location "C:\Titanium\Standard - ServerCAL\"


#Start-Process -Wait -FilePath "C:\Titanium\Standard - ServerCAL\setup.exe" -ArgumentList ("/q /IACCEPTSQLSERVERLICENSETERMS /ACTION=Install /FEATURES=SQL /UpdateEnabled=False /INSTANCENAME=MSSQLSERVER /SECURITYMODE=SQL /SAPWD="$password" /SQLSVCACCOUNT="NT Service\MSSQLSERVER" /SQLSYSADMINACCOUNTS=".\Administrator" /AGTSVCACCOUNT="NT Service\SQLSERVERAGENT"
Start-Process -Wait -FilePath 'C:\Titanium\SSMS-Setup-ENU.exe'  -ArgumentList ("/Install /quiet /passive /norestart") -Verb RunAs -PassThru
# aws s3 cp 'C:\Program Files\Microsoft SQL Server\150\SSMS????\Log\Summary.txt' $SQLLogfilePath

#install ARS
$ARSinstallationPath= "s3://prod-dependencies-app1-artifacts-bucket/Active_Roles_7.4.3.zip"
Write-host " ARS installation"
aws s3 cp $ARSinstallationPath c:\temp\app1\Active_Roles_7.4.3.zip
Expand-Archive -LiteralPath c:\temp\app1\Active_Roles_7.4.3.zip -DestinationPath C:\temp\app1\ -force
Write-host "Downloaded ARS setup file "
Start-Process -Wait -FilePath 'C:\temp\app1\Active_Roles_7.4.3\ActiveRoles.exe' -ArgumentList '/quiet','/install','/ADDLOCAL=Tool','/IAcceptActiveRolesLicenseTerms' -Verb RunAs -PassThru

"Instance Started at " + (get-date) | Out-File -Encoding Ascii C:\log.txt
if (!(gwmi win32_computersystem).partofdomain) {

		"Server hasn't joined domain, start processing at " + (get-date) | Out-File -Encoding Ascii -append C:\log.txt
		Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "fPromptForPassword" -Value 0
		$secrets_manager_secret_id = "/dependencies-prod-app1/srvpwd"
		$secret_manager = Get-SECSecretValue -SecretId $secrets_manager_secret_id
		$secret = $secret_manager.SecretString | ConvertFrom-Json
		$srvpwd = ConvertTo-SecureString -String $secret.srvpwd -Force -AsPlainText
		New-LocalUser "srvadmin" -Password $srvpwd -ErrorAction SilentlyContinue
		Add-LocalGroupMember -Group 'Administrators' -Member "srvadmin" -ErrorAction SilentlyContinue
		Write-Host "Added local admin srvadmin" | Out-File -Encoding Ascii -append C:\log.txt
		$token = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token-ttl-seconds" = "21600"} -Method PUT -Uri http://169.254.169.254/latest/api/token
		$instance_id = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token" = $token} -Method GET -Uri http://169.254.169.254/latest/meta-data/instance-id
		$environment = aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[*].Instances[].[Tags[?Key=='Environment']|[0].Value]" --output text
		#$lhd = aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[*].Instances[].[Tags[?Key=='lhd']|[0].Value]" --output text
		$app = aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[*].Instances[].[Tags[?Key=='ApplicationName']|[0].Value]" --output text
		$environment = ($environment.substring(0,1)).ToUpper()
		#$lhd = ($lhd.substring(0,2)).ToUpper()
		$app = ($app.substring(0,3)).ToUpper()
		$hostname = $env:computername
		$hostname = "CLDR" + "CON" + $environment + $app + $hostname.substring($hostname.Length-2)
		aws ec2 create-tags --resources $instance_id --tags Key=Name,Value=$hostname	
		Write-Host "Changed Server name" | Out-File -Encoding Ascii -append C:\log.txt
<<<<<<< .merge_file_a20028
		$ou = "OU=Servers,OU=NSWH-Titanium86-NonProd-AWS-TEST,OU=Self-Managed,OU=Cloud,OU=State Resources - Automation,DC=nswhealth,DC=net"
		$secrets_manager_secret_id = "/dependencies-train-app1/adcred"
=======
		$ou = "OU=GPOBlocked,OU=Servers,OU=app1-poc-NSWH-aws,OU=Self-Managed,OU=Cloud,OU=State Resources - Automation,DC=nswhealth,DC=net"
		$secrets_manager_secret_id = "/dependencies-prod-app1/adcred"
>>>>>>> .merge_file_a29184
		$secret_manager = Get-SECSecretValue -SecretId $secrets_manager_secret_id
		$secret = $secret_manager.SecretString | ConvertFrom-Json
		$user = $secret.admuser
		$password = $secret.admpwd | ConvertTo-SecureString -AsPlainText -Force
		$creds = New-Object System.Management.Automation.PSCredential -ArgumentList ($user, $password)
		New-QADComputer $hostname -Credential $creds -ParentContainer $ou -ObjectAttributes @{edsajoincomputertodomain='nswhealth\6458460B38'} -service ActiveRolesMMC.nswhealth.net -Proxy
		Rename-Computer -NewName $hostname -ErrorAction SilentlyContinue
		Add-Computer -NewName $hostname -DomainName 'nswhealth.net' -Credential $creds -Options JoinWithNewName -restart -Force -ErrorAction SilentlyContinue

}else {

	Add-LocalGroupMember -Group "Administrators" -Member "nswhealth\app1-poc-NSWH-aws-Administrators" -ErrorAction SilentlyContinue
}

</powershell>





 