#$TitaniumWeb_S3path="s3://prod-dependencies-app1-artifacts-bucket/TitaniumWebInstallerBootstrap_104.86.184_r125176_repacked.msi"
#$TitaniumApp_S3path="s3://prod-dependencies-app1-artifacts-bucket/Titanium_Installer_12.0.86.165_r122060_repacked.zip"
#$ARSinstallationPath= "s3://prod-dependencies-app1-artifacts-bucket/Active_Roles_7.4.3.zip"
#$dotNet35Path= "s3://prod-dependencies-app1-artifacts-bucket/dotnet35.zip"
#$citrixpath= "s3://prod-dependencies-app1-artifacts-bucket/XenApp_and_XenDesktop_1912_LTSR-CU3.zip"
#$controlUpagentPath= "s3://prod-dependencies-app1-artifacts-bucket/ControlUpAgent-net45-x64-8.2.0.758-signed.msi"

$versionNumber=$env:versionNumber
#$TitaniumWeb_S3path="s3://train-dependencies-app1-artifacts-bucket/TitaniumWebInstallerBootstrap_104.86.184_r125176_repacked.msi"
#$TitaniumApp_S3path="s3://train-dependencies-app1-artifacts-bucket/Titanium_Installer_12.0.86.165_r122060_repacked.zip"
#$ARSinstallationPath= "s3://train-dependencies-app1-artifacts-bucket/Active_Roles_7.4.3.zip"
#$dotNet35Path= "s3://train-dependencies-app1-artifacts-bucket/dotnet35.zip"

$artifactBucket = "s3://$env:bucketname"
$TitBucket = $artifactBucket #"s3://train-dependencies-app1-artifacts-bucket"


# Setup installation directory

mkdir c:\temp\app1
Set-Location c:\temp\app1

# Set the Timezone 

$timezone=Get-TimeZone -ListAvailable | where-object {$_.DisplayName -like "*Canberra, Melbourne, Sydney*"} |select-object -ExpandProperty "ID"
Set-TimeZone -Id $timezone -PassThru

# Miscellaneous 

Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "fPromptForPassword" -Value 0
Remove-Item C:\temp\app1 -Force -Recurse -ErrorAction SilentlyContinue
$ChromePath= "$TitBucket/ChromeStandaloneSetup64.exe"
Write-host " Chrome installation"
aws s3 cp $ChromePath c:\temp\app1\ChromeStandaloneSetup64.exe
Write-host "Downloaded Chrome setup file "
Start-Process -Wait -FilePath 'C:\temp\app1\ChromeStandaloneSetup64.exe' -ArgumentList '/silent','/install' -Verb RunAs -PassThru

$nppPath= "$TitBucket/npp.8.1.3.Installer.x64.exe"
Write-host "Notepad++ installation"
aws s3 cp $nppPath c:\temp\app1\npp.8.1.3.Installer.x64.exe
Write-host "Downloaded Notepad++ setup file "
Start-Process -Wait -FilePath 'C:\temp\app1\npp.8.1.3.Installer.x64.exe' -ArgumentList '/S' -Verb RunAs -PassThru

#install .net 3.5
$dotNet35Path= "$TitBucket/dotnet35.zip" 
aws s3 cp $dotNet35Path c:\temp\app1\dotnet35.zip
Expand-Archive -LiteralPath c:\temp\app1\dotnet35.zip -DestinationPath C:\temp\app1 -force
Start-Process dism.exe -ArgumentList '/online','/enable-feature','/featurename:NetFX3','/All','/Source:C:\temp\app1\sources\sxs','/LimitAccess','/quiet' -Wait  -Verb RunAs -PassThru

#install ARS
$ARSinstallationPath= "$TitBucket/Active_Roles_7.4.3.zip"
Write-host " ARS installation"
aws s3 cp $ARSinstallationPath c:\temp\app1\Active_Roles_7.4.3.zip
Expand-Archive -LiteralPath c:\temp\app1\Active_Roles_7.4.3.zip -DestinationPath C:\temp\app1\ -force
Write-host "Downloaded ARS setup file "
Start-Process -Wait -FilePath 'C:\temp\app1\Active_Roles_7.4.3\ActiveRoles.exe' -ArgumentList '/quiet','/install','/ADDLOCAL=Tool','/IAcceptActiveRolesLicenseTerms' -Verb RunAs -PassThru

#enable IIS components

# Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServer
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpErrors
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-StaticContent
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-DefaultDocument
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-HealthAndDiagnostics
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpLogging
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-Performance
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-Security
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-RequestFiltering
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-BasicAuthentication
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-WindowsAuthentication
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationDevelopment
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationInit
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIExtensions
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIFilter
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebSockets
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-DirectoryBrowsing
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpCompressionStatic
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpCompressionDynamic
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-ManagementConsole
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-IIS6ManagementCompatibility
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-Metabase
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-WMICompatibility
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-LegacySnapIn
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-LegacyScripts
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-LoggingLibraries
# Enable-WindowsOptionalFeature -Online -FeatureName NetFx4Extended-ASPNET45
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-NetFxExtensibility45
# Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASPNET45
# Get-WindowsOptionalFeature -Online | Where-Object {$_.State -like "Disabled" -and $_.FeatureName -like "*WCF*"} | % {Enable-WindowsOptionalFeature -Online -FeatureName $_.FeatureName -All}
# disable-WindowsOptionalFeature -Online -FeatureName WCF-TCP-Activation45
# disable-WindowsOptionalFeature -Online -FeatureName WCF-Pipe-Activation45
# disable-WindowsOptionalFeature -Online -FeatureName WCF-MSMQ-Activation45
# disable-WindowsOptionalFeature -Online -FeatureName WCF-TCP-PortSharing45

# Install Tit App
$TiAppPath= "$TitBucket/TiAppInstall.zip"    
aws s3 cp $TiAppPath c:\temp\app1\TiAppInstall.zip
Expand-Archive -LiteralPath c:\temp\app1\TiAppInstall.zip -DestinationPath C:\temp\app1\ -Force 
msiexec /i "C:\temp\app1\TiAppInstall\Titanium_Installer_12.0.86.165_r122060.msi" TRANSFORMS="C:\temp\app1\TiAppInstall\TiStaging.mst" /qn

start-sleep -Seconds 60

# Import registry key items before Tit Web installation   
# $RegPath = "$TitBucket/TiWebInstReg.reg"
# $RegLocal = "c:\temp\app1\TiWebInstReg.reg"
# aws s3 cp $RegPath $RegLocal
# Start-Process -Wait 'reg' -ArgumentList 'import','c:\temp\app1\TiWebInstReg.reg' -Verb RunAs -PassThru

# # Install Tit Web
# $filename = "Setup_TitaniumWeb.msi"
# $TiWebPath = "$TitBucket/$filename"
# $WebLocal = "c:\temp\app1\$filename"
# aws s3 cp $TiWebPath $WebLocal
# Get-Service AWSAgentUpdater -ErrorAction SilentlyContinue | Stop-Service -ErrorAction SilentlyContinue
# Get-Service AWSAgent -ErrorAction SilentlyContinue | Stop-Service -ErrorAction SilentlyContinue
# $secrets_manager_secret_id = "/dependencies-prod-app1/app1DB"
# $secret_manager = Get-SECSecretValue -SecretId $secrets_manager_secret_id
# $secret = $secret_manager.SecretString | ConvertFrom-Json
# $password = $secret.TiWebpwd
# $Options = @("/i",$WebLocal,"/log","c:\temp\web_install_log.txt","EulaAcceptCheckbox=1","ADDLOCAL=ConfigureIISFeature", "WEBSITE_APPPOOL=TitaniumAppPool", "DSN_MSSQL_SERVER=APP1-aws-DB-prod.nswhealth.net","DSN_MSSQL_DATABASE=Staging_titanium", "DSN_MSSQL_USERNAME=TitaniumWebServices", "DSN_MSSQL_PASSWORD=`"$password`"", "/qn")
# Start-Process msiexec.exe -Wait -ArgumentList $Options -Verb RunAs -PassThru 

# start-sleep -Seconds 60

# Copy EXACT.ini file to local to replace empty one
#Remove-Item $env:userprofile\WINDOWS\EXACT.ini -ErrorAction SilentlyContinue
#Remove-Item C:\Windows\EXACT.ini -ErrorAction SilentlyContinue
#$ExactiniPath = "$TitBucket/EXACT.INI"
#$ExactiniLocal = "c:\temp\app1\EXACT.ini"
#aws s3 cp $ExactiniPath $ExactiniLocal
#Copy-Item $ExactiniLocal c:\Windows\EXACT.ini
#Copy-Item $ExactiniLocal $env:userprofile\WINDOWS\EXACT.ini

# Copy license to local
# $LicPath= "$TitBucket/NSW-AWS-Staging.lic"
# Write-host "Copying Web License file"
# aws s3 cp $LicPath c:\temp\app1\NSW-AWS-Staging.lic

# Citrix Components installation

# Downloading Cirtix ControlUp Agent

# $controlUpagentPath= "$TitBucket/ControlUpAgent-net45-x64-8.2.0.758-signed.msi"
# write-host "Downloading Controlagent setup file"
# aws s3 cp $controlUpagentPath c:\temp\app1\ControlUpAgent-net45-x64-8.2.0.758-signed.msi
# write-host "Downloaded ControlUagentagent setup file"
#Start-Process msiexec.exe -Wait -ArgumentList '/i', 'c:\temp\app1\ControlUpAgent-net45-x64-8.2.0.758-signed.msi','/quiet' 
#write-host "Controlagent Installation Completed successfully"

#start-sleep -Seconds 60

# Downloading the Cirtix VDA Agent Setup files

# Write-host " Downloading the Cirtix VDA Agent setup files"
# $citrixpath= "$TitBucket/XenApp_and_XenDesktop_1912_LTSR-CU3.zip"
# aws s3 cp $citrixpath c:\temp\app1\CitrixVDA.zip
# Expand-Archive -LiteralPath c:\temp\app1\CitrixVDA.zip -DestinationPath c:\temp\app1\CitrixVDA\
# write-host "Downloaded Citrix Component"

# $cirtixfolder = Get-ChildItem -Directory c:\temp\app1\CitrixVDA\ |Select-Object -ExpandProperty "Name"
# $cirtxiexepath= 'c:\temp\app1\CitrixVDA\' + $cirtixfolder + '\x64\XenDesktop Setup\XenDesktopVDASetup.exe'
# $Options = @('/QUIET', '/NOREBOOT','/COMPONENTS VDA','/ENABLE_REAL_TIME_TRANSPORT','/ENABLE_HDX_UDP_PORTS','/ENABLE_REMOTE_ASSISTANCE','/ENABLE_HDX_PORTS', '/OPTIMIZE', '/MASTERIMAGE')
# Start-Process -Wait -FilePath $cirtxiexepath  -ArgumentList $Options -Verb RunAs -PassThru
# write-host "Citrix component installed but requires reboot to complete setup"

# Verify Titanium Web and update web.config file

# $TitWebFile = "C:\Program Files\Spark Dental Technology\TitaniumWeb\license.svc"

# if ((Test-Path -Path $TitWebFile)) {
#     write-host "Titanium folder found, updating web.config file. "
#     $hostname = $env:computername
#     $placeholder = "placeholder"
#     $filename = "C:\Program Files\Spark Dental Technology\TitaniumWeb\Web.config"
#     ((Get-Content -path $filename -Raw -ErrorAction SilentlyContinue) -replace $hostname,$placeholder) | Set-Content -Path $filename
# } else {
#     "Titanium Web is not installed !! Skipped. "
# }

# Post install


#Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "fPromptForPassword" -Value 0
#$secrets_manager_secret_id = "/dependencies-prod-app1/srvpwd"
#$secret_manager = Get-SECSecretValue -SecretId $secrets_manager_secret_id
#$secret = $secret_manager.SecretString | ConvertFrom-Json
#$srvpwd = ConvertTo-SecureString -String $secret.srvpwd -Force -AsPlainText
#New-LocalUser "srvadmin" -Password $srvpwd -ErrorAction SilentlyContinue
#Add-LocalGroupMember -Group 'Administrators' -Member "srvadmin" -ErrorAction SilentlyContinue
#"Added local admin srvadmin" | Out-File -Encoding Ascii -append C:\log.txt

#rm C:\Windows\EXACT.ini -ErrorAction SilentlyContinue
$ExactiniPath = "$TitBucket/EXACT.ini"
$ExactiniLocal = "c:\temp\app1\EXACT.ini"
aws s3 cp $ExactiniPath $ExactiniLocal
Cp $ExactiniLocal c:\Windows\EXACT.ini -ErrorAction SilentlyContinue
"Copied EXACT.ini file" | Out-File -Encoding Ascii -append C:\log.txt

start-sleep -Seconds 60

# Install Adobe and office

$Officemsi_S3path="$TitBucket/office2013.zip"
$AdobeinstallPath= "$TitBucket/AcroRdrDC2100120155_en_US.exe"

Write-host " Adobe reader Installation"
$Options = @('/sAll','/rs','/msi','EULA_ACCEPT=YES')
aws s3 cp $AdobeinstallPath c:\temp\app1\AcroRdrDC2100120155_en_US.exe
Write-host "Downloaded ARS setup file "
Start-Process -Wait -FilePath 'c:\temp\app1\AcroRdrDC2100120155_en_US.exe' -ArgumentList $Options -Verb RunAs -PassThru

write-host "Downloading the MS Office "
aws s3 cp $Officemsi_S3path c:\temp\app1\office2013.zip
write-host "Extracting the zip file "
Expand-Archive -LiteralPath c:\temp\app1\office2013.zip -DestinationPath c:\temp\app1\office2013\
write-host "Installing the MSOffice setup"
$Options = @('/adminfile "app1_Excel_n_Word.msp"')
Start-Process -Wait -FilePath 'c:\temp\app1\office2013\MS Office 2013 SP1 x64 -PSADT-052019\Files\setup.exe' -ArgumentList $Options -Verb RunAs -PassThru

start-sleep -Seconds 60


# Activating citrix
$user = "NT AUTHORITY\SYSTEM"
$command = "C:\Windows\System32\cmd.exe"
$argument = "/C C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe "" set-location 'C:\Program Files\Microsoft Office\Office15\'; cscript ospp.vbs /sethst:kms.nswhealth.net ; cscript ospp.vbs /act; Disable-ScheduledTask -TaskName 'setup-Office-KMS'"""
$action = New-ScheduledTaskAction -Execute $command -Argument $argument
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName "setup-Office-KMS" -Trigger $trigger -Action $Action -RunLevel Highest -Force -User $user

# Clean up C:\temp folder

#Remove-Item -path c:\temp\* -recurse

Remove-Item -path c:\temp\app1 -force -recurse -ErrorAction SilentlyContinue

write-host "Instance is ready to proceed to build Image"

