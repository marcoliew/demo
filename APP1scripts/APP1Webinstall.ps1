#$TitaniumWeb_S3path="s3://prod-dependencies-app1-artifacts-bucket/TitaniumWebInstallerBootstrap_104.86.184_r125176_repacked.msi"
#$TitaniumApp_S3path="s3://prod-dependencies-app1-artifacts-bucket/Titanium_Installer_12.0.86.165_r122060_repacked.zip"
#$ARSinstallationPath= "s3://prod-dependencies-app1-artifacts-bucket/Active_Roles_7.4.3.zip"
#$dotNet35Path= "s3://prod-dependencies-app1-artifacts-bucket/dotnet35.zip"
#$citrixpath= "s3://prod-dependencies-app1-artifacts-bucket/XenApp_and_XenDesktop_1912_LTSR-CU3.zip"
#$controlUpagentPath= "s3://prod-dependencies-app1-artifacts-bucket/ControlUpAgent-net45-x64-8.2.0.758-signed.msi"

$versionNumber=$env:versionNumber
$lhd = $env:lhd
$environment = $env:environment
$artifactBucket = $env:bucketname #"train-dependencies-app1-artifacts-bucket"
$ad_secret_id = $env:ad_secret_id
$sql_secret_id = $env:sql_secret_id
$CWagent = "s3://$env:bucketname/amazon-cloudwatch-agent.msi"



# Obtain AD secrets
$secret_manager_ad = Get-SECSecretValue -SecretId $ad_secret_id
$secret_ad = $secret_manager_ad.SecretString | ConvertFrom-Json
$tiAdmin = $secret_ad.tiAdmin
$tiPwd	 = $secret_ad.tiPwd
$inPort  = $secret_ad.inPort
$outServer = $secret_ad.outServer

# Obtain sql secrets
$secret_manager_sql = Get-SECSecretValue -SecretId $sql_secret_id
$secret_sql = $secret_manager_sql.SecretString | ConvertFrom-Json
$TiWebuser = $secret_sql.TiWebuser
$TiWebpwd = $secret_sql.TiWebpwd

# Setup installation directory

mkdir c:\temp\app1
Set-Location c:\temp\app1

# Set the Timezone 

$timezone=Get-TimeZone -ListAvailable | where-object {$_.DisplayName -like "*Canberra, Melbourne, Sydney*"} |select-object -ExpandProperty "ID"
Set-TimeZone -Id $timezone -PassThru

# Miscellaneous 

Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "fPromptForPassword" -Value 0
Remove-Item C:\temp\app1 -Force -Recurse -ErrorAction SilentlyContinue
$ChromePath= "s3://$artifactBucket/ChromeStandaloneSetup64.exe"
Write-host " Chrome installation"
aws s3 cp $ChromePath c:\temp\app1\ChromeStandaloneSetup64.exe
Write-host "Downloaded Chrome setup file "
Start-Process -Wait -FilePath 'C:\temp\app1\ChromeStandaloneSetup64.exe' -ArgumentList '/silent','/install' -Verb RunAs -PassThru

$nppPath= "s3://$artifactBucket/npp.8.1.3.Installer.x64.exe"
Write-host "Notepad++ installation"
aws s3 cp $nppPath c:\temp\app1\npp.8.1.3.Installer.x64.exe
Write-host "Downloaded Notepad++ setup file "
Start-Process -Wait -FilePath 'C:\temp\app1\npp.8.1.3.Installer.x64.exe' -ArgumentList '/S' -Verb RunAs -PassThru
 

#install .net 3.5
$dotNet35Path= "s3://$artifactBucket/dotnet35.zip" 
aws s3 cp $dotNet35Path c:\temp\app1\dotnet35.zip
Expand-Archive -LiteralPath c:\temp\app1\dotnet35.zip -DestinationPath C:\temp\app1 -force
Start-Process dism.exe -wait -ArgumentList '/online','/enable-feature','/featurename:NetFX3','/All','/Source:C:\temp\app1\sources\sxs','/LimitAccess','/quiet' -Verb RunAs -PassThru

#install ARS
$ARSinstallationPath= "s3://$artifactBucket/Active_Roles_7.4.3.zip"
Write-host " ARS installation"
aws s3 cp $ARSinstallationPath c:\temp\app1\Active_Roles_7.4.3.zip
Expand-Archive -LiteralPath c:\temp\app1\Active_Roles_7.4.3.zip -DestinationPath C:\temp\app1\ -force
Write-host "Downloaded ARS setup file "
Start-Process -Wait -FilePath 'C:\temp\app1\Active_Roles_7.4.3\ActiveRoles.exe' -ArgumentList '/quiet','/install','/ADDLOCAL=Tool','/IAcceptActiveRolesLicenseTerms' -Verb RunAs -PassThru

#enable IIS components

Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer
Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpErrors
Enable-WindowsOptionalFeature -Online -FeatureName IIS-StaticContent
Enable-WindowsOptionalFeature -Online -FeatureName IIS-DefaultDocument
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HealthAndDiagnostics
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpLogging
Enable-WindowsOptionalFeature -Online -FeatureName IIS-Performance
Enable-WindowsOptionalFeature -Online -FeatureName IIS-Security
Enable-WindowsOptionalFeature -Online -FeatureName IIS-RequestFiltering
Enable-WindowsOptionalFeature -Online -FeatureName IIS-BasicAuthentication
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WindowsAuthentication
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationDevelopment
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationInit
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIExtensions
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIFilter
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebSockets
Enable-WindowsOptionalFeature -Online -FeatureName IIS-DirectoryBrowsing
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpCompressionStatic
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpCompressionDynamic
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ManagementConsole
Enable-WindowsOptionalFeature -Online -FeatureName IIS-IIS6ManagementCompatibility
Enable-WindowsOptionalFeature -Online -FeatureName IIS-Metabase
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WMICompatibility
Enable-WindowsOptionalFeature -Online -FeatureName IIS-LegacySnapIn
Enable-WindowsOptionalFeature -Online -FeatureName IIS-LegacyScripts
Enable-WindowsOptionalFeature -Online -FeatureName IIS-LoggingLibraries
Enable-WindowsOptionalFeature -Online -FeatureName NetFx4Extended-ASPNET45
Enable-WindowsOptionalFeature -Online -FeatureName IIS-NetFxExtensibility45
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASPNET45
Get-WindowsOptionalFeature -Online | Where-Object {$_.State -like "Disabled" -and $_.FeatureName -like "*WCF*"} | % {Enable-WindowsOptionalFeature -Online -FeatureName $_.FeatureName -All}
disable-WindowsOptionalFeature -Online -FeatureName WCF-TCP-Activation45
disable-WindowsOptionalFeature -Online -FeatureName WCF-Pipe-Activation45
disable-WindowsOptionalFeature -Online -FeatureName WCF-MSMQ-Activation45
disable-WindowsOptionalFeature -Online -FeatureName WCF-TCP-PortSharing45

# Install Tit App
$TiAppPath= "s3://$artifactBucket/TiAppInstall.zip"    
aws s3 cp $TiAppPath c:\temp\app1\TiAppInstall.zip
Expand-Archive -LiteralPath c:\temp\app1\TiAppInstall.zip -DestinationPath C:\temp\app1\ -Force 
msiexec /i "C:\temp\app1\TiAppInstall\Titanium_Installer_12.0.86.165_r122060.msi" TRANSFORMS="C:\temp\app1\TiAppInstall\TiStaging.mst" /qn

start-sleep -Seconds 60

# Import registry key items before Tit Web installation   
$RegPath = "s3://$artifactBucket/TiWebInstReg.reg"
$RegLocal = "c:\temp\app1\TiWebInstReg.reg"
aws s3 cp $RegPath $RegLocal
((Get-Content -path $RegLocal -Raw -ErrorAction SilentlyContinue) -replace "#envholder#",$environment) | Set-Content -Path $RegLocal
#((Get-Content -path $RegLocal -Raw -ErrorAction SilentlyContinue) -replace "#lhdholder#",$lhd.Substring(0,$lhd.Length-3).ToUpper()) | Set-Content -Path $RegLocal
Start-Process -Wait 'reg' -ArgumentList 'import',$RegLocal -Verb RunAs -PassThru

# Install Tit Web
$filename = "Setup_TitaniumWeb.msi"
$TiWebPath = "s3://$artifactBucket/$filename"
$WebLocal = "c:\temp\app1\$filename"
aws s3 cp $TiWebPath $WebLocal
Get-Service AWSAgentUpdater -ErrorAction SilentlyContinue | Stop-Service -ErrorAction SilentlyContinue
Get-Service AWSAgent -ErrorAction SilentlyContinue | Stop-Service -ErrorAction SilentlyContinue
#$secrets_manager_secret_id = "/dependencies-train-app1/sqldb/creds"

# $PoshResponse = aws secretsmanager get-secret-value --secret-id $secretid | ConvertFrom-Json
# Parse the response and convert the Secret String JSON into an object
# $Creds = $PoshResponse.SecretString | ConvertFrom-Json
# $TiDentaluser = $Creds.TiDentaluser
# $TiDentalpwd = $Creds.TiDentalpwd
#$secret_manager = Get-SECSecretValue -SecretId $secrets_manager_secret_id
#$secret = $secret_manager.SecretString | ConvertFrom-Json
#$password = $secret.TiWebpwd
#echo $password
#msiexec.exe /qn /i $WebLocal /log c:\temp\web_install_log.txt EulaAcceptCheckbox=1 ADDLOCAL=ConfigureIISFeature WEBSITE_APPPOOL=TitaniumAppPool DSN_MSSQL_SERVER=APP1-aws-DB-prod.nswhealth.net DSN_MSSQL_DATABASE=Staging_titanium DSN_MSSQL_USERNAME=TitaniumWebServices DSN_MSSQL_PASSWORD=$password
#Start-Process -Wait msiexec.exe -ArgumentList '/qn', '/i', '$WebLocal', '/log', 'c:\temp\web_install_log.txt', 'EulaAcceptCheckbox=1', 'ADDLOCAL=ConfigureIISFeature', 'WEBSITE_APPPOOL=TitaniumAppPool', 'DSN_MSSQL_SERVER=APP1-aws-DB-prod.nswhealth.net', 'DSN_MSSQL_DATABASE=Staging_titanium', 'DSN_MSSQL_USERNAME=TitaniumWebServices', 'DSN_MSSQL_PASSWORD=$password'
#$Options = @('/i',$WebLocal,'/log','c:\temp\web_install_log.txt','EulaAcceptCheckbox=1','ADDLOCAL=ConfigureIISFeature', 'WEBSITE_APPPOOL=TitaniumAppPool', 'DSN_MSSQL_SERVER=APP1-aws-DB-prod.nswhealth.net','DSN_MSSQL_DATABASE=Staging_titanium', 'DSN_MSSQL_USERNAME=xex', 'DSN_MSSQL_PASSWORD=$password', '/qn')
#$Options = @("/i",$WebLocal,"/log","c:\temp\web_install_log.txt","DSN_MSSQL_PASSWORD=`"$password`"", "/qn")
$Options = @("/i",$WebLocal,"/log","c:\temp\web_install_log.txt","EulaAcceptCheckbox=1","ADDLOCAL=ConfigureIISFeature", "WEBSITE_APPPOOL=TitaniumAppPool", "DSN_MSSQL_SERVER=APP1-aws-DB-prod.nswhealth.net","DSN_MSSQL_DATABASE=Staging_titanium", "DSN_MSSQL_USERNAME=`"$TiWebuser`"", "DSN_MSSQL_PASSWORD=`"$TiWebpwd`"", "/qn")
Start-Process msiexec.exe -Wait -ArgumentList $Options -Verb RunAs -PassThru 

start-sleep -Seconds 60

# Copy EXACT.ini file to local to replace empty one
# Remove-Item $env:userprofile\WINDOWS\EXACT.ini -ErrorAction SilentlyContinue
# Remove-Item C:\Windows\EXACT.ini -ErrorAction SilentlyContinue
# $ExactiniPath = "s3://$artifactBucket/$lhd/" + "EXACT_$lhd.ini"
# $ExactiniLocal = "c:\temp\app1\EXACT.ini"
# aws s3 cp $ExactiniPath $ExactiniLocal
# Cp $ExactiniLocal c:\Windows\EXACT.ini -ErrorAction SilentlyContinue
# Copy license to local
# $LicPath= "s3://$artifactBucket/$lhd/NSW-eHealth-$lhd-Prod-60-CDBS.lic"
# Write-host "Copying Web License file"
# aws s3 cp $LicPath c:\temp\app1\NSW-AWS-Staging.lic

# Install HL7 component on the same server
$HL7Path= "s3://$artifactBucket/TitaniumHL7Setup_12.0.86.165_r122060.msi"
aws s3 cp $HL7Path c:\temp\app1\TitaniumHL7Setup_12.0.86.165_r122060.msi
Start-Process msiexec.exe -Wait -ArgumentList '/i', 'C:\temp\app1\TitaniumHL7Setup_12.0.86.165_r122060.msi', '/qn'
# $HL7Local = "C:\Program Files (x86)\Spark Dental Technology\Titanium HL7"
# $regPath = $HL7Local + "\RuntimeKeyReg.exe"
# $licPath = $HL7Local + "\3.7 runtime 151003.lic"
# do {
#     Write-Host "HL7 hasn't installed, wait 5 seconds"
#     Start-Sleep -s 5
# } until ((Test-Path -Path $LicPath))
# Start-Process -Wait -FilePath "`"$regPath`"" -Argument "`"$licPath`" /s" -Verb RunAs -PassThru

# Open ports for HL7
if ($environment="prod")
{
    $esb_port = "4500"
}
else 
{
    $esb_port = "4501"
}
New-NetFirewallRule -DisplayName "HL7 inbound" -Direction inbound -LocalPort $esb_port -Protocol TCP -Profile Any -Action Allow
New-NetFirewallRule -DisplayName "HL7 inbound" -Direction inbound -LocalPort 8000 -Protocol TCP -Profile Any -Action Allow
New-NetFirewallRule -DisplayName "HL7 inbound" -Direction outbound -LocalPort 8000 -Protocol TCP -Profile Any -Action Allow

start-sleep -Seconds 60

# Verify Titanium Web and update web.config file

$TitWebFile = "C:\Program Files\Spark Dental Technology\TitaniumWeb\license.svc"

if ((Test-Path -Path $TitWebFile)) {
    write-host "Titanium folder found, updating web.config file. "
    $hostname = $env:computername
    $placeholder = "placeholder"
    $filename = "C:\Program Files\Spark Dental Technology\TitaniumWeb\Web.config"
    ((Get-Content -path $filename -Raw -ErrorAction SilentlyContinue) -replace $hostname,$placeholder) | Set-Content -Path $filename
} else {
    "Titanium Web is not installed !! Skipped. "
}

# Verify HL7 and apply Symphonia license

$HL7Local = "C:\Program Files (x86)\Spark Dental Technology\Titanium HL7"
$regPath = $HL7Local + "\RuntimeKeyReg.exe"
$licPath = $HL7Local + "\3.7 runtime 151003.lic"
if ((Test-Path -Path $LicPath)) {
    # "HL7 folder found, applying license. "
    # Start-Process -Wait -FilePath "`"$regPath`"" -Argument "`"$licPath`" /s" -Verb RunAs -PassThru
    # start-sleep -Seconds 10
    "Applying HL7 Reg config settings "
    $HL7regPath = "s3://$artifactBucket/HL7Service.reg"
    $HL7regLocal = "c:\temp\app1\HL7Service.reg"
    aws s3 cp $HL7regPath $HL7regLocal
    #((Get-Content -path $HL7regLocal -Raw -ErrorAction SilentlyContinue) -replace "#dsplaceholder#",$lhd.ToUpper()) | Set-Content -Path $HL7regLocal
    ((Get-Content -path $HL7regLocal -Raw -ErrorAction SilentlyContinue) -replace "#webuserholder#",$tiAdmin) | Set-Content -Path $HL7regLocal
    ((Get-Content -path $HL7regLocal -Raw -ErrorAction SilentlyContinue) -replace "#webpwdholder#",$tiPwd) | Set-Content -Path $HL7regLocal
    ((Get-Content -path $HL7regLocal -Raw -ErrorAction SilentlyContinue) -replace "#portplaceholder#",$inPort) | Set-Content -Path $HL7regLocal
    ((Get-Content -path $HL7regLocal -Raw -ErrorAction SilentlyContinue) -replace "#serverplaceholder#",$outServer) | Set-Content -Path $HL7regLocal
    #Start-Process -Wait 'reg' -ArgumentList 'import',$HL7regLocal -Verb RunAs -PassThru		
} else {
    "HL7 is not installed !! Skipped. "
}

start-sleep -Seconds 20

# Add DNS Suffixes (append) nswhealth.net 
$DNSsuffixes =  "nswhealth.net","ap-southeast-2.ec2-utilities.amazonaws.com","ap-southeast-2.compute.internal"
Invoke-Wmimethod -Class win32_networkadapterconfiguration -Name setDNSSuffixSearchOrder -ArgumentList @($DNSSuffixes),$null #-ErrorAction SilentlyContinue

# Copy CDBSExtract.ps1

mkdir "C:\ProgramData\Spark Dental Technology\Scripts\"


# CW part
$CWagent="s3://$artifactBucket/amazon-cloudwatch-agent.msi"
Write-host "Cloudwatch agent installation"
aws s3 cp $CWagent 'c:\temp\app1\amazon-cloudwatch-agent.msi'
Start-Process msiexec.exe -Wait -ArgumentList '/quiet /i c:\temp\app1\amazon-cloudwatch-agent.msi' -Verb RunAs -PassThru

# Made folder for C:\ProgramData\Spark Dental Technology\Scripts "
mkdir "C:\ProgramData\Spark Dental Technology\Scripts\" -ErrorAction SilentlyContinue
mkdir "C:\ProgramData\Spark Dental Technology\HL7\" -ErrorAction SilentlyContinue

# Apply HL7 license from AMI
Write-host "Applying HL7 license. "
.$regPath $licPath /s

# Clean up C:\temp folder   

#Remove-Item -path c:\temp\* -recurse

#Remove-Item -path c:\temp\app1 -force -recurse -ErrorAction SilentlyContinue

# Enable telnet
dism /online /Enable-Feature /FeatureName:TelnetClient

write-host "Instance is ready to proceed to build Image"

