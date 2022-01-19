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


$token = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token-ttl-seconds" = "21600"} -Method PUT -Uri http://169.254.169.254/latest/api/token
$instance_id = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token" = $token} -Method GET -Uri http://169.254.169.254/latest/meta-data/instance-id
$environment = aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[*].Instances[].[Tags[?Key=='environment']|[0].Value]" --output text
$app = aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[*].Instances[].[Tags[?Key=='app']|[0].Value]" --output text

$artificatpath ="s3://$environment-dependencies-$app-artifacts-bucket"


$ssms_path="$artificatpath/SQL/SSMS-Setup-ENU.exe"

Write-host "SSMS Installation"
$Options = @('/install','/quiet','/norestart')
aws s3 cp $ssms_path c:\Titanium\SSMS-Setup-ENU.exe
Write-host "Downloaded SSMS setup file "
Start-Process -Wait -FilePath 'c:\Titanium\SSMS-Setup-ENU.exe' -ArgumentList $Options -Verb RunAs -PassThru


$SSM_cwagent = "/dependencies-$app-$environment/cw_agent_config"
Set-Location "C:\Program Files\Amazon\AmazonCloudWatchAgent"
write-host "Configuring Cloudwatch agent"
.\amazon-cloudwatch-agent-ctl.ps1 -a fetch-config -m EC2 -s -c ssm:$SSM_cwagent
write-host "Starting Cloudwatch_agent"
.\amazon-cloudwatch-agent-ctl.ps1 -m ec2 -a Start
"Started Cloudwatch agent" + (get-date)  | Out-File -Encoding Ascii -append C:\log.txt

## code for domain Join
$secrets_manager_secret_id = "/dependencies-$environment-$app/adcred"
$secret_manager = Get-SECSecretValue -SecretId $secrets_manager_secret_id
$secret = $secret_manager.SecretString | ConvertFrom-Json
$user = "nswhealth\" + $secret.admuser
$password = $secret.admpwd | ConvertTo-SecureString -AsPlainText -Force
$srvpwd = ConvertTo-SecureString -String $secret.srvpwd -Force -AsPlainText
$ou=$secret.ou
$creds = [PSCredential]::new($user, $password)
$adlocaladmingroup="nswhealth\" + $secret.adlocaladmingroup
$adtargetgroup="nswhealth\" + $secret.adtargetgroup
$ADgroup=$secret.domaingroup

"Instance Started at " + (get-date) | Out-File -Encoding Ascii C:\log.txt
if (!(gwmi win32_computersystem).partofdomain) {

		"Server hasn't joined domain, start processing at " + (get-date) | Out-File -Encoding Ascii -append C:\log.txt
		Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "fPromptForPassword" -Value 0

		
		New-LocalUser "srvadmin" -Password $srvpwd -ErrorAction SilentlyContinue
		Add-LocalGroupMember -Group 'Administrators' -Member "srvadmin" -ErrorAction SilentlyContinue
		Write-Host "Added local admin srvadmin" | Out-File -Encoding Ascii -append C:\log.txt
		
		$environment = ($environment.substring(0,1)).ToUpper()
		$app = ($app.substring(0,3)).ToUpper()
		$hostname = $env:computername
		$hostname = "CLDR" + "SSRS" + $environment + $app + $hostname.substring($hostname.Length-2)

		aws ec2 create-tags --resources $instance_id --tags Key=Name,Value=$hostname	
		Write-Host "Changed Server name" | Out-File -Encoding Ascii -append C:\log.txt
		Add-Computer -NewName $hostname -OUPath ("OU=Servers," + $ou) -DomainName nswhealth.net -Credential $creds -Restart
}else {
	Connect-QADService -Credential $creds -Proxy -Service activerolesmmc.nswhealth.net
	New-QADGroup -ParentContainer ("OU=Groups," + $ou) -Name "L-NSWH-LocalAdmins-$($env:COMPUTERNAME)" -Description "Local admin access for $($env:COMPUTERNAME)" -GroupScope DomainLocal -Member $adlocaladmingroup
	Add-QADGroupMember -Identity $adtargetgroup -Member $env:COMPUTERNAME
	Disconnect-QADService
	Add-LocalGroupMember -Group "Administrators" -Member $ADgroup -ErrorAction SilentlyContinue
	#Sleep for 5 mins to allow replication of the Local admin group to occur before rebooting so that the local admin group is added as a local admin on the machine.
	Start-Sleep -Seconds (2*60)
}
Restart-Computer
</powershell>
<persist>true</persist>





 