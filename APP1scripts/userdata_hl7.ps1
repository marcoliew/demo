<powershell>
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
		$lhd = aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[*].Instances[].[Tags[?Key=='lhd']|[0].Value]" --output text
		$app = aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[*].Instances[].[Tags[?Key=='app']|[0].Value]" --output text
		$environment = ($environment.substring(0,1)).ToUpper()
		$lhd = ($lhd.substring(0,2)).ToUpper()
		$app = ($app.substring(0,3)).ToUpper()
		$hostname = $env:computername
		$hostname = "CLDR" + "HL7" + $environment + $app + $lhd + $hostname.substring($hostname.Length-2)
		aws ec2 create-tags --resources $instance_id --tags Key=Name,Value=$hostname	
		Write-Host "Changed Server name" | Out-File -Encoding Ascii -append C:\log.txt
		$ou = "OU=Servers,NSWH-Titanium86-NonProd-AWS-TEST,OU=Self-Managed,OU=Cloud,OU=State Resources - Automation,DC=nswhealth,DC=net"
		$secrets_manager_secret_id = "/dependencies-train-app1/adcred"
		$secret_manager = Get-SECSecretValue -SecretId $secrets_manager_secret_id
		$secret = $secret_manager.SecretString | ConvertFrom-Json
		$user = $secret.admuser
		$password = $secret.admpwd | ConvertTo-SecureString -AsPlainText -Force
		$creds = New-Object System.Management.Automation.PSCredential -ArgumentList ($user, $password)
		New-QADComputer $hostname -Credential $creds -ParentContainer $ou -ObjectAttributes @{edsajoincomputertodomain='nswhealth\6458460B38'} -service ActiveRolesMMC.nswhealth.net -Proxy
		Rename-Computer -NewName $hostname -ErrorAction SilentlyContinue
		Add-Computer -NewName $hostname -DomainName nswhealth.net -Credential $creds -Options JoinWithNewName -restart -Force -ErrorAction SilentlyContinue	
} else {
	Add-LocalGroupMember -Group "Administrators" -Member "nswhealth\app1-poc-NSWH-aws-Administrators" -ErrorAction SilentlyContinue
}
</powershell>
<persist>true</persist>