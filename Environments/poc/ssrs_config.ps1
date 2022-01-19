<powershell>
function Get-ConfigSet()
{
	return Get-WmiObject -namespace "root\Microsoft\SqlServer\ReportServer\RS_SSRS\v15\Admin" -class MSReportServer_ConfigurationSetting -ComputerName $env:ComputerName
}

# Allow importing of sqlps module
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force

# Retrieve the current configuration
$configset = Get-ConfigSet

If (! $configset.IsInitialized)
{
	# Get the ReportServer and ReportServerTempDB creation script
	[string]$dbscript = $configset.GenerateDatabaseCreationScript("ReportServer", 1033, $false).Script

	# Import the SQL Server PowerShell module
	Import-Module sqlserver -DisableNameChecking | Out-Null

	# Establish a connection to the database server (localhost)
	$conn = New-Object Microsoft.SqlServer.Management.Common.ServerConnection -ArgumentList $env:ComputerName
	$conn.ApplicationName = "SSRS Configuration Script"
	$conn.StatementTimeout = 0
	$conn.Connect()
	$smo = New-Object Microsoft.SqlServer.Management.Smo.Server -ArgumentList $conn

	# Create the ReportServer and ReportServerTempDB databases
	$db = $smo.Databases["master"]
	$db.ExecuteNonQuery($dbscript)

	# Set permissions for the databases
	$dbscript = $configset.GenerateDatabaseRightsScript($configset.WindowsServiceIdentityConfigured, "ReportServer", $false, $true).Script
	$db.ExecuteNonQuery($dbscript)

	# Set the database connection info
	$configset.SetDatabaseConnection("(local)", "ReportServer", 2, "", "")

	$configset.SetVirtualDirectory("ReportServerWebService", "ReportServer", 1033)
	$configset.ReserveURL("ReportServerWebService", "http://+:80", 1033)

	# For SSRS 2016-2017 only, older versions have a different name
	$configset.SetVirtualDirectory("ReportServerWebApp", "Reports", 1033)
	$configset.ReserveURL("ReportServerWebApp", "http://+:80", 1033)

	$configset.InitializeReportServer($configset.InstallationID)

	# Re-start services?
	$configset.SetServiceState($false, $false, $false)
	Restart-Service $configset.ServiceName
	$configset.SetServiceState($true, $true, $true)

	# Update the current configuration
	$configset = Get-ConfigSet

	# Output to screen
	$configset.IsReportManagerEnabled
	$configset.IsInitialized
	$configset.IsWebServiceEnabled
	$configset.IsWindowsServiceEnabled
	$configset.ListReportServersInDatabase()
	$configset.ListReservedUrls();

	$inst = Get-WmiObject -namespace "root\Microsoft\SqlServer\ReportServer\RS_SSRS\v15" -class MSReportServer_Instance -ComputerName $env:ComputerName

	$inst.GetReportServerUrls()
}

$SQLRSModule= "s3://nswh-provider-ap-southeast-2-inf-497427545767/SSRS/Ti_SSRS_DEV/reportingservicestools.zip"
$ReportsFolder = "s3://nswh-provider-ap-southeast-2-inf-497427545767/SSRS/Ti_SSRS_DEV/SourceFiles"
$UploadSummary = "s3://nswh-provider-ap-southeast-2-inf-497427545767/SSRS/Ti_SSRS_DEV/SSRS_Upload_Summary.txt"

cd\
mkdir Titanium

Set-Location c:\Titanium

# Start Logging

$ErrorActionPreference="SilentlyContinue"
Stop-Transcript | out-null
$ErrorActionPreference = "Continue"
Start-Transcript -path C:\Titanium\SSRS_Upload_Summary.txt -append
#write-host "setting execution policy"
#Get-Item -Path "HKLM:\SOFTWARE\Microsoft\Cryptography\Protect\Providers\df9d8cd0-1501-11d1-8c7a-00c04fc297eb" | New-ItemProperty -Name 'ProtectionPolicy' -Value '1' -PropertyType DWORD
write-host "Downloading the Reporting Services Powershell module"
aws s3 cp $SQLRSModule c:\Titanium\reportingservicestools.zip
write-host "Extracting The Reporting Services Powershell module"
Expand-Archive -LiteralPath c:\Titanium\reportingservicestools.zip -DestinationPath C:\Titanium\reportingservicestools
Copy-Item  'C:\Titanium\reportingservicestools' -Destination 'C:\Program Files\WindowsPowerShell\Modules\reportingservicestools' -Recurse
aws s3 cp $ReportsFolder c:\Titanium\SourceFiles --recursive

# Declare Variables
$ServerLocal = "$env:COMPUTERNAME"
$reportServerUri = "http://$($ServerLocal)/ReportServer/ReportService2019.asmx?wsdl"
$SourceFiles = "c:\Titanium\SourceFiles"
$newRSFolderPath = "Titanium Reports"
$Environment = "POC"
# Email Configuration variables
$Instance = "SSRS"
$smtpserver = "smtp.nswhealth.net"
$Instance = "SSRS"
$ReportServerVersion = "15"
$SenderAddress = "EHNSW-TitaniumReport@health.nsw.gov.au"
# Security Configuration variables
$ADBrowserRoleGroups = "NSWHEALTH\L-NSWH-Oral Health SESLHD SRSS Executive","NSWHEALTH\L-NSWH-Oral Health SESLHD SRSS Manager","NSWHEALTH\L-NSWH-Oral Health SESLHD SRSS User"
$ADContentMgrRoleGroups = "NSWHEALTH\L-NSWH-Oral Health SESLHD SRSS Admin","SESAHS\53004290","SESAHS\53027602","NSWHEALTH\app1-poc-NSWH-aws-Administrators"
# Retrieve username and password - Parse the response and convert the Secret String JSON into an object
$PoshResponse = aws secretsmanager get-secret-value --secret-id $Environment/app1DB | ConvertFrom-Json
$Creds = $PoshResponse.SecretString | ConvertFrom-Json
$password=$Creds.ssrspwd
$username=$Creds.ssrsuser
# New DataSource variables
$newRSDSFolder = "Datasources"
$newRSDSName = "Staging_Titanium"
$newRSDSDesc =  $Environment + " "+"Shared Datasource"
$newRSDSExtension = "SQL"
$newRSDSConnectionString = "Initial Catalog=STAGING_Titanium; Data Source=APP1-aws-db-stage.nswhealth.net;database=STAGING_Titanium"
$newRSDSCredentialRetrieval = "Store"
# Using PSCredentials assigned values from Secret store
Function New-PSCredential
{
    param(
            [Parameter(Mandatory = $True)]
            [string]$UserName,
            [Parameter(Mandatory = $True)]
            [string]$Password
        )
       $SecurePassword = ConvertTo-SecureString $Password -AsPlainText -Force
       $ps_credential = New-Object System.Management.Automation.PSCredential ($UserName, $SecurePassword)
       Return $ps_credential 
}

$newRSDSCredential = New-PSCredential -User $userName -Password $password
$DataSourcePath = "/$newRSFolderPath/$newRSDSFolder/$newRSDSName"

Import-Module -Name ReportingServicesTools

# Configure email settings for Report Server (SMTP)

Write-host "Applying email configuration"

Set-RsEmailSettings -ReportServerInstance $Instance -ReportServerVersion $ReportServerVersion -Authentication None -SmtpServer $smtpserver -SenderAddress $SenderAddress
           
Write-host "Email Settings Applied"

# Create SSRS Folders on Destination based on Source Folder Layout

Write-host "Starting Reports Upload and Configuration"

Get-ChildItem $SourceFiles -Recurse -Directory -Name | ForEach-Object {
  # Split the relative input path into leaf (directory name)
  # and parent path, and convert the parent path to the target parent path
  # by prepending "/" and converting path-internal "\" instances to "/". 
  $SubFolderParentPath = '/' + ((Split-Path -Parent $_) -replace '\\', '/')                           
  $SubFolderName = Split-Path -Leaf $_
  try{
    New-RsFolder -ReportServerUri $reportServerUri -Path $SubFolderParentPath -FolderName $SubFolderName 
         
  }
  catch {
      # Report the specific error that occurred, accessible via $_
       
  }
}

Write-host "Folders/Sub-Folders Created"

# Upload RDL files to corresponding folders on new Report Server
Write-RsFolderContent -ReportServerUri $reportServerUri -Path "$SourceFiles\" -Recurse -Destination "/"

Write-host "Reports Uploaded"

# Create datasource

Write-host "Create New Datasource"

New-RsFolder -ReportServerUri $reportServerUri -Path "/$newRSFolderPath" -FolderName $newRSDSFolder
New-RsDataSource -ReportServerUri $reportServerUri -RsFolder "/$newRSFolderPath/$newRSDSFolder" -Name $newRSDSName -Description $newRSDSDesc -Extension $newRSDSExtension -ConnectionString $newRSDSConnectionString -CredentialRetrieval $newRSDSCredentialRetrieval -DatasourceCredentials $newRSDSCredential

Write-host "DataSource Created"

# Set report datasource
Get-RsCatalogItems -ReportServerUri $reportServerUri -RsFolder "/$newRSFolderPath" -Recurse | Where-Object TypeName -eq 'Report' | ForEach-Object {
    $dataSource = Get-RsItemReference -ReportServerUri $reportServerUri -Path $_.Path
    if ($dataSource -ne $null) {
        Set-RsDataSourceReference -ReportServerUri $reportServerUri -Path $_.Path -DataSourceName $dataSource.Name -DataSourcePath $DataSourcePath
        Write-Output "Changed datasource $($dataSource.Name) set to $DataSourcePath on report $($_.Path) "
    }
    else {
        Write-Warning "Report $($_.Path) does not contain a datasource"
    }
}

Write-host "DataSoure Applied"

Write-host "Applying Security Group permissions"

#Set Folder Permission - Browser
$ADBrowserRoleGroups | ForEach-Object {Grant-RsCatalogItemRole -ReportServerUri $reportServerUri -Identity $_ -RoleName 'Browser'  -Path "/$newRSFolderPath"}

#Set Folder Permission - Content Manager
$ADContentMgrRoleGroups | ForEach-Object {Grant-RsCatalogItemRole -ReportServerUri $reportServerUri -Identity $_ -RoleName 'Content Manager'  -Path "/$newRSFolderPath"}

Write-Host "Security Group permissions Applied"

#Restart SSRS Service

Get-Service 'SQLServerReportingServices' | Restart-Service;

Write-Host "End of Script"

Stop-Transcript

aws s3 cp 'C:\Titanium\SSRS_Upload_Summary.txt' $UploadSummary
</powershell>