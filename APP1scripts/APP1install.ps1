$TitaniumWeb_S3path="s3://poc-swapping/TitaniumWebInstallerBootstrap_104.86.184_r125176_repacked.msi"
$TitaniumApp_S3path="s3://poc-swapping/Titanium_Installer_12.0.86.165_r122060_repacked.zip"
$ARSinstallationPath= "s3://poc-swapping/Active_Roles_7.4.3.zip"
$dotNet35Path= "s3://poc-swapping/dotnet35.zip"
$citrixpath= "s3://poc-swapping/XenApp_and_XenDesktop_1912_LTSR-CU3.zip"
$controlUpagentPath= "s3://poc-swapping/ControlUpAgent-net45-x64-8.2.0.758-signed.msi"

$versionNumber=$env:versionNumber
#$TitaniumWeb_S3path="s3://poc-swapping/TitaniumWebInstallerBootstrap_104.86.184_r125176_repacked.msi"
#$TitaniumApp_S3path="s3://poc-swapping/Titanium_Installer_12.0.86.165_r122060_repacked.zip"
#$ARSinstallationPath= "s3://poc-swapping/Active_Roles_7.4.3.zip"
#$dotNet35Path= "s3://poc-swapping/dotnet35.zip"

# Setup installation directory

mkdir c:\temp\app1
Set-Location c:\temp\app1

# Set the Timezone 

$timezone=Get-TimeZone -ListAvailable | where-object {$_.DisplayName -like "*Canberra, Melbourne, Sydney*"} |select-object -ExpandProperty "ID"
Set-TimeZone -Id $timezone -PassThru

# Miscellaneous 

Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "fPromptForPassword" -Value 0
Remove-Item C:\temp\app1 -Force -Recurse -ErrorAction SilentlyContinue
$ChromePath= "s3://poc-swapping/ChromeStandaloneSetup64.exe"
Write-host " Chrome installation"
aws s3 cp $ChromePath c:\temp\app1\ChromeStandaloneSetup64.exe
Write-host "Downloaded Chrome setup file "
Start-Process -Wait -FilePath 'C:\temp\app1\ChromeStandaloneSetup64.exe' -ArgumentList '/silent','/install' -Verb RunAs -PassThru

$nppPath= "s3://poc-swapping/npp.8.1.3.Installer.x64.exe"
Write-host "Notepad++ installation"
aws s3 cp $nppPath c:\temp\app1\npp.8.1.3.Installer.x64.exe
Write-host "Downloaded Notepad++ setup file "
Start-Process -Wait -FilePath 'C:\temp\app1\npp.8.1.3.Installer.x64.exe' -ArgumentList '/S' -Verb RunAs -PassThru
 

#install .net 3.5
$dotNet35Path= "s3://poc-swapping/dotnet35.zip" 
aws s3 cp $dotNet35Path c:\temp\app1\dotnet35.zip
Expand-Archive -LiteralPath c:\temp\app1\dotnet35.zip -DestinationPath C:\temp\app1
Start-Process dism.exe -ArgumentList '/online','/enable-feature','/featurename:NetFX3','/All','/Source:C:\temp\app1\sources\sxs','/LimitAccess','/quiet' -Wait  -Verb RunAs -PassThru

#install ARS
$ARSinstallationPath= "s3://poc-swapping/Active_Roles_7.4.3.zip"
Write-host " ARS installation"
aws s3 cp $ARSinstallationPath c:\temp\app1\Active_Roles_7.4.3.zip
Expand-Archive -LiteralPath c:\temp\app1\Active_Roles_7.4.3.zip -DestinationPath C:\temp\app1\
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


# Titanium Webserver installation

write-host "Downloading the Titanium Webserver setup file"
aws s3 cp $TitaniumWeb_S3path c:\temp\app1\TitaniumWeb.msi
write-host "Installing the Titanium Webserver setup file"
Start-Process msiexec.exe -Wait -ArgumentList "/i", "c:\temp\app1\TitaniumWeb.msi","/quiet" 
write-host "Installation Completed successfully"

# Titanium Application installation 
write-host "Temporarily disable aws agent/agent updater service"

write-host "Downloading the Titanium App setup file "
aws s3 cp $TitaniumApp_S3path c:\temp\app1\TitaniumApp.zip
write-host "Extracting the zip file "
Expand-Archive -LiteralPath c:\temp\app1\TitaniumApp.zip -DestinationPath c:\temp\app1\TitaniumApp
write-host "Installing the Titanium App setup file"
Start-Process msiexec.exe -Wait -ArgumentList "/i", "c:\temp\app1\TitaniumApp\Titanium_Installer_12.0.86.165_r122060.msi","/quiet" 
Get-WindowsOptionalFeature -Online | Where-Object {$_.State -like "Disabled" -and $_.FeatureName -like "*WCF*"} | % {Enable-WindowsOptionalFeature -Online -FeatureName $_.FeatureName -All}
disable-WindowsOptionalFeature -Online -FeatureName WCF-TCP-Activation45
disable-WindowsOptionalFeature -Online -FeatureName WCF-Pipe-Activation45
disable-WindowsOptionalFeature -Online -FeatureName WCF-MSMQ-Activation45
disable-WindowsOptionalFeature -Online -FeatureName WCF-TCP-PortSharing45

#Install Tit App
$TiAppPath= "s3://poc-swapping/TiAppInstall.zip"    
aws s3 cp $TiAppPath c:\temp\app1\TiAppInstall.zip
Expand-Archive -LiteralPath c:\temp\app1\TiAppInstall.zip -DestinationPath C:\temp\app1\ -Force 
msiexec /i "C:\temp\app1\TiAppInstall\Titanium_Installer_12.0.86.165_r122060.msi" TRANSFORMS="C:\temp\app1\TiAppInstall\TiStaging.mst" /qn

#import registry key items before Tit Web installation   
$RegPath = "s3://poc-swapping/TiWebInstReg.reg"
$RegLocal = "c:\temp\app1\TiWebInstReg.reg"
aws s3 cp $RegPath $RegLocal
Start-Process -Wait 'reg' -ArgumentList 'import','c:\temp\app1\TiWebInstReg.reg' -Verb RunAs -PassThru

#install Tit Web
$filename = "Setup_TitaniumWeb.msi"
$TiWebPath = "s3://poc-swapping/$filename"
$WebLocal = "c:\temp\app1\$filename"
aws s3 cp $TiWebPath $WebLocal
Get-Service AWSAgentUpdater -ErrorAction SilentlyContinue | Stop-Service -ErrorAction SilentlyContinue
Get-Service AWSAgent -ErrorAction SilentlyContinue | Stop-Service -ErrorAction SilentlyContinue
$secrets_manager_secret_id = "POC/app1DB"
$secret_manager = Get-SECSecretValue -SecretId $secrets_manager_secret_id
$secret = $secret_manager.SecretString | ConvertFrom-Json
$password = $secret.password
msiexec.exe /qn /i $WebLocal /log c:\temp\web_install_log.txt EulaAcceptCheckbox=1 ADDLOCAL=ConfigureIISFeature WEBSITE_APPPOOL=TitaniumAppPool DSN_MSSQL_SERVER=APP1-aws-DB-stage.nswhealth.net DSN_MSSQL_DATABASE=Staging_titanium DSN_MSSQL_USERNAME=TitaniumWebServices DSN_MSSQL_PASSWORD=$password

#Copy well done EXACT.ini file to local
Remove-Item $env:userprofile\WINDOWS\EXACT.ini -ErrorAction SilentlyContinue
Remove-Item C:\Windows\EXACT.ini -ErrorAction SilentlyContinue
$ExactiniPath = "s3://poc-swapping/EXACT.ini"
$ExactiniLocal = "c:\temp\app1\EXACT.ini"
aws s3 cp $ExactiniPath $ExactiniLocal
Copy-Item $ExactiniLocal c:\Windows\EXACT.ini
#Copy-Item $ExactiniLocal $env:userprofile\WINDOWS\EXACT.ini
 
#Copy license to local
$LicPath= "s3://poc-swapping/NSW-AWS-Staging.lic"
Write-host "Copying Web License file"
aws s3 cp $LicPath c:\temp\app1\NSW-AWS-Staging.lic

# Install HL7 component on the same server
$HL7Path= "s3://poc-swapping/TitaniumHL7Setup_12.0.86.165_r122060.msi"
aws s3 cp $HL7Path c:\temp\app1\TitaniumHL7Setup_12.0.86.165_r122060.msi
msiexec /i "C:\temp\app1\TitaniumHL7Setup_12.0.86.165_r122060.msi" /qn
."C:\Program Files (x86)\Spark Dental Technology\Titanium HL7\RuntimeKeyReg.exe" "C:\Program Files (x86)\Spark Dental Technology\Titanium HL7\3.7 runtime 151003.lic" /s

# Citrix Components installation

# Downloading Cirtix ControlUp Agent

write-host "Downloading Controlagent setup file"
aws s3 cp $controlUpagentPath c:\temp\app1\ControlUpAgent-net45-x64-8.2.0.758-signed.msi
write-host "Downloaded ControlUagentagent setup file"
Start-Process msiexec.exe -Wait -ArgumentList '/i', 'c:\temp\app1\ControlUpAgent-net45-x64-8.2.0.758-signed.msi','/quiet' 
write-host "Controlagent Installation Completed successfully"

# Downloading the Cirtix VDA Agent Setup files

Write-host " Downloading the Cirtix VDA Agent setup files"
aws s3 cp $citrixpath c:\temp\app1\CitrixVDA.zip
Expand-Archive -LiteralPath c:\temp\app1\CitrixVDA.zip -DestinationPath c:\temp\app1\CitrixVDA\
write-host "Downloaded Citrix Component"

$cirtixfolder = Get-ChildItem -Directory c:\temp\app1\CitrixVDA\ |Select-Object -ExpandProperty "Name"
$cirtxiexepath= 'c:\temp\app1\CitrixVDA\' + $cirtixfolder + '\x64\XenDesktop Setup\XenDesktopVDASetup.exe'
$Options = @('/QUIET', '/NOREBOOT','/COMPONENTS VDA','/ENABLE_REAL_TIME_TRANSPORT','/ENABLE_HDX_UDP_PORTS','/ENABLE_REMOTE_ASSISTANCE','/ENABLE_HDX_PORTS', '/OPTIMIZE', '/MASTERIMAGE')
Start-Process -Wait -FilePath $cirtxiexepath  -ArgumentList $Options -Verb RunAs -PassThru
write-host "Citrix component installed but requires reboot to complete setup"

# Clean up C:\temp folder


Remove-Item -path c:\temp\* -recurse
 
#place holder Citrix components

# Clean up C:\temp folder

Remove-Item -path c:\temp\app1 -force -recurse -ErrorAction SilentlyContinue

write-host "Instance is ready to proceed to build Image"

