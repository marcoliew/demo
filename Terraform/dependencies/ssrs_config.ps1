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


"Instance Started at " + (get-date) | Out-File -Encoding Ascii C:\log.txt
if (!(gwmi win32_computersystem).partofdomain) {

		"Server hasn't joined domain, start processing at " + (get-date) | Out-File -Encoding Ascii -append C:\log.txt
		Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "fPromptForPassword" -Value 0
		$secrets_manager_secret_id = "/dependencies-train-app1/srvpwd"
		$secret_manager = Get-SECSecretValue -SecretId $secrets_manager_secret_id
		$secret = $secret_manager.SecretString | ConvertFrom-Json
		$srvpwd = ConvertTo-SecureString -String $secret.srvpwd -Force -AsPlainText
		New-LocalUser "srvadmin" -Password $srvpwd -ErrorAction SilentlyContinue
		Add-LocalGroupMember -Group 'Administrators' -Member "srvadmin" -ErrorAction SilentlyContinue
		Write-Host "Added local admin srvadmin" | Out-File -Encoding Ascii -append C:\log.txt
		$token = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token-ttl-seconds" = "21600"} -Method PUT -Uri http://169.254.169.254/latest/api/token
		$instance_id = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token" = $token} -Method GET -Uri http://169.254.169.254/latest/meta-data/instance-id
		$environment = aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[*].Instances[].[Tags[?Key=='environment']|[0].Value]" --output text
		#$lhd = aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[*].Instances[].[Tags[?Key=='lhd']|[0].Value]" --output text
		$app = aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[*].Instances[].[Tags[?Key=='app']|[0].Value]" --output text
		$environment = ($environment.substring(0,1)).ToUpper()
		#$lhd = ($lhd.substring(0,2)).ToUpper()
		$app = ($app.substring(0,3)).ToUpper()
		$hostname = $env:computername
		$hostname = "CLDR" + "SSRS" + $environment + $app + $hostname.substring($hostname.Length-2)
		aws ec2 create-tags --resources $instance_id --tags Key=Name,Value=$hostname	
		Write-Host "Changed Server name" | Out-File -Encoding Ascii -append C:\log.txt
		$ou = "OU=Servers,OU=NSWH-Titanium86-NonProd-AWS-TEST,OU=Self-Managed,OU=Cloud,OU=State Resources - Automation,DC=nswhealth,DC=net"
		$secrets_manager_secret_id = "/dependencies-train-app1/adcred"
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





 