<powershell>
$log = "C:\log.txt"
"Srv started " + (get-date) | Out-File -Encoding Ascii -append $log
$token = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token-ttl-seconds" = "21600"} -Method PUT -Uri http://169.254.169.254/latest/api/token
$instance_id = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token" = $token} -Method GET -Uri http://169.254.169.254/latest/meta-data/instance-id
$lic = aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[*].Instances[].[Tags[?Key=='licensed']|[0].Value]" --output text
if($lic -ne "true") {
	$envmnt = aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[*].Instances[].[Tags[?Key=='environment']|[0].Value]" --output text
	$lhd = aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[*].Instances[].[Tags[?Key=='lhd']|[0].Value]" --output text
	$lhds = $lhd.Substring(0,$lhd.Length-3)
	$app = aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[*].Instances[].[Tags[?Key=='app']|[0].Value]" --output text
	$artbkt = aws ec2 describe-instances --instance-ids $instance_id --query "Reservations[*].Instances[].[Tags[?Key=='artifactBucket']|[0].Value]" --output text
	$env_name = $envmnt
	$envmnt = ($envmnt.substring(0,1)).ToUpper()
	$scrt_mgr_id = "/dependencies-$env_name-$app/adcred" 
	$secret_manager = Get-SECSecretValue -SecretId $scrt_mgr_id
	$secret = $secret_manager.SecretString | ConvertFrom-Json
	$dp = "nswhealth\"
	$user = $dp + $secret.admuser
	$password = $secret.admpwd | ConvertTo-SecureString -AsPlainText -Force
	$srvpwd = ConvertTo-SecureString -String $secret.srvpwd -Force -AsPlainText
	$ou= $secret.ou
	$srv_ou = "OU=Servers," + $ou
	$ADgroup=$secret.domaingroup
	$creds = [PSCredential]::new($user, $password)
	$adlcadmg=$dp + $secret.adlocaladmingroup
	$adtgg=$dp + $secret.adtargetgroup
	$certpwd = $secret.certpwd | ConvertTo-SecureString -AsPlainText -Force 
	$tiAdmin = $secret.tiAdmin
	$tiPwd	 = $secret.tiPwd
	$t 		 = "hl7_"+$lhds+"_ac"
	$p       = "hl7_"+$lhds+"_pwd"
	$hl7_ac = $secret.$t
	$hl7_u	= $dp + $hl7_ac
	$hl7_pwd = $secret.$p
	"Lic n applied" | Out-File -Encoding Ascii -append $log
	if (!(gwmi win32_computersystem).partofdomain) {
		"Srv n joined " + (get-date) | Out-File -Encoding Ascii -append $log
		Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\Terminal Services" -Name "fPromptForPassword" -Value 0
		New-LocalUser "srvadmin" -Password $srvpwd -ErrorAction SilentlyContinue
		Add-LocalGroupMember -Group 'Administrators' -Member "srvadmin" -ErrorAction SilentlyContinue
		"+ srvadmin " + (get-date) | Out-File -Encoding Ascii -append $log
		$hostname = $env:computername
		$placeholder = "placeholder"
		$hostname = "CLDR" + "WEB" + $envmnt + ($app.substring(0,3)).ToUpper() + ($lhd.substring(0,2)).ToUpper() + $hostname.substring($hostname.Length-2)
		$fqdn = $hostname + ".nswhealt.net"
		$filename = "C:\Program Files\Spark Dental Technology\TitaniumWeb\Web.config"
		((Get-Content -path $filename -Raw -ErrorAction SilentlyContinue) -replace $placeholder,$fqdn) | Set-Content -Path $filename
		((Get-Content -path $filename -Raw -ErrorAction SilentlyContinue) -replace "#lhdholder#",$lhds) | Set-Content -Path $filename
		"Update web.conf hostname " + (get-date) | Out-File -Encoding Ascii -append $log
		"Old name " + $env:computername + (get-date) | Out-File -Encoding Ascii -append $log
		"New name " + $hostname + (get-date) | Out-File -Encoding Ascii -append $log
		rm $env:userprofile\WINDOWS\EXACT.ini -ErrorAction SilentlyContinue
		rm C:\Windows\EXACT.ini -ErrorAction SilentlyContinue
		$ExactiniPath = "s3://$artbkt/EXACT_web.ini"
		$ExactiniLocal = "c:\temp\app1\EXACT.ini"
		aws s3 cp $ExactiniPath $ExactiniLocal
		((Get-Content -path $ExactiniLocal -Raw -ErrorAction SilentlyContinue) -replace "#ph-lhd#",$lhds) | Set-Content -Path $ExactiniLocal
		((Get-Content -path $ExactiniLocal -Raw -ErrorAction SilentlyContinue) -replace "#ph-env#",$env_name) | Set-Content -Path $ExactiniLocal
		Cp $ExactiniLocal c:\Windows\EXACT.ini -ErrorAction SilentlyContinue
		"Copy EXACT " + (get-date) | Out-File -Encoding Ascii -append $log
		$siteName = "Default Web Site"
		$cert = "s3://$artbkt/titaniumweb.pfx"
		aws s3 cp $cert c:\temp\app1\titaniumweb.pfx
		Import-PfxCertificate -FilePath C:\temp\app1\titaniumweb.pfx cert:\localMachine\My -Password $certpwd
		$cert = Get-ChildItem Cert:\LocalMachine\My | Where-Object {$_.FriendlyName -eq "app1 WEB SSL Certificate"}
		New-WebBinding -Name $siteName -IP "*" -Port 443 -Protocol https
		$binding = Get-WebBinding -Name $siteName -Protocol "https"
		$binding.AddSslCertificate($cert.GetCertHashString(), "my")
		"Imp cert " + (get-date) | Out-File -Encoding Ascii -append $log
		Import-Module WebAdministration
		Set-ItemProperty IIS:\AppPools\TitaniumAppPool -name "startMode" -Value "AlwaysRunning"
		Set-ItemProperty IIS:\AppPools\TitaniumAppPool -Name processModel.idleTimeout "0"
		Set-ItemProperty IIS:\AppPools\TitaniumAppPool -Name recycling.disallowOverlappingRotation -value True
		Set-ItemProperty IIS:\AppPools\TitaniumAppPool -Name recycling.periodicRestart.time -value ([TimeSpan]::FromMinutes(0))
		Set-ItemProperty -Path "IIS:\AppPools\TitaniumAppPool" -Name Recycling.periodicRestart.schedule -Value @{value="2:00"}
		Set-ItemProperty "IIS:\Sites\Default Web Site" -Name applicationDefaults.preloadEnabled -Value True
		"Set IIS " + (get-date)  | Out-File -Encoding Ascii -append $log
        $SSM_cwagent = "/dependencies-$env_name-$app/cw_agent_config"
        Set-Location "C:\Program Files\Amazon\AmazonCloudWatchAgent"
        .\amazon-cloudwatch-agent-ctl.ps1 -a fetch-config -m EC2 -s -c ssm:$SSM_cwagent
        .\amazon-cloudwatch-agent-ctl.ps1 -m ec2 -a Start
		"CWag " + (get-date)  | Out-File -Encoding Ascii -append $log
		Add-Computer -NewName $hostname -DomainName 'nswhealth.net'  -OUPath ($srv_ou) -Credential $creds -restart
	} else {
		"Joined,lic n applied " + (get-date) | Out-File -Encoding Ascii -append $log
		$token = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token-ttl-seconds" = "21600"} -Method PUT -Uri http://169.254.169.254/latest/api/token
		$instance_id = Invoke-RestMethod -Headers @{"X-aws-ec2-metadata-token" = $token} -Method GET -Uri http://169.254.169.254/latest/meta-data/instance-id
		$hostname = $env:computername
		aws ec2 create-tags --resources $instance_id --tags Key=Name,Value=$hostname	
		"hostname tag " + (get-date) | Out-File -Encoding Ascii -append $log
		$user 	= "Users"
		$tmp = [System.IO.Path]::GetTempFileName()
		secedit.exe /export /cfg $tmp
		$st = Get-Content -Path $tmp
		$ac = New-Object System.Security.Principal.NTAccount($user)
		$sid = $ac.Translate([System.Security.Principal.SecurityIdentifier])
		for($i=0;$i -lt $st.Count;$i++){
			if($st[$i] -match "SeInteractiveLogonRight") {
				$st[$i] += ",*$($sid.Value)"
			}		
		}
		$st | Out-File $tmp
		secedit.exe /configure /db secedit.sdb /cfg $tmp  /areas User_RIGHTS
		Remove-Item -Path $tmp
		gpupdate /force
		"Set LSP " + (get-date) | Out-File -Encoding Ascii -append $log
        Connect-QADService -Credential $creds -Proxy -Service activerolesmmc.nswhealth.net
        New-QADGroup -ParentContainer ("OU=Groups," + $ou) -Name "L-NSWH-LocalAdmins-$($env:COMPUTERNAME)" -Description "Local admin access for $($env:COMPUTERNAME)" -GroupScope DomainLocal -Member $adlcadmg
        Add-QADGroupMember -Identity $adtgg -Member "$($env:COMPUTERNAME)"
		Add-QADGroupMember -Identity "L-NSWH-LocalAdmins-$($env:COMPUTERNAME)" -Member $hl7_u
        Disconnect-QADService
        Add-LocalGroupMember -Group "Administrators" -Member $ADgroup -ErrorAction SilentlyContinue
		Add-LocalGroupMember -Group "Administrators" -Member $hl7_u -ErrorAction SilentlyContinue
		"loc ADg" + (get-date) | Out-File -Encoding Ascii -append $log
		$action = New-ScheduledTaskAction -Execute 'c:\windows\system32\forfiles.exe' -Argument '-p "C:\inetpub\logs" -s -m *.log /D -60 /C "cmd /c del @path"'
		$tri =  New-ScheduledTaskTrigger -Daily -At 2am
		$st = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -DontStopOnIdleEnd
		Register-ScheduledTask -Action $action -Trigger $tri -RunLevel Highest -User $user -Password $password -Settings $st -TaskName "AppLogDump" -Description "Daily dump of Applog"
		"Reg cleanup " + (get-date) | Out-File -Encoding Ascii -append $log
		$HL7L = "C:\Program Files (x86)\Spark Dental Technology\Titanium HL7"
		$rgP = $HL7L + "\RuntimeKeyReg.exe"
		$licP = $HL7L + "\3.7 runtime 151003.lic"
		.$rgP $licP /s
		"HL7 lic " + (get-date) | Out-File -Encoding Ascii -append $log
	    $HL7regL = "c:\temp\app1\HL7Service.reg"
    	((Get-Content -path $HL7regL -Raw -ErrorAction SilentlyContinue) -replace "#dsplaceholder#",$lhds) | Set-Content -Path $HL7regL
		Start-Process -Wait 'reg' -ArgumentList 'import',$HL7regL -Verb RunAs -PassThru
		$7sv = Get-WmiObject -ComputerName $env:computername -Query "SELECT * FROM Win32_Service WHERE Name = 'TitaniumHL7Service'"
		$7sv.Change($null,$null,$null,$null,$null,$null,"$hl7_ac@nswhealth.net","$hl7_pwd") | Out-Null
		$7sv.StopService() | Out-Null
		$7sv.StartService()
		sc.exe failure TitaniumHL7Service reset= 0 actions= restart/60000
		"HL7 srvac " + (get-date) | Out-File -Encoding Ascii -append $log
		Set-ItemProperty -path "HKCU:\Software\Microsoft\Windows\CurrentVersion\WinTrust\Trust Providers\Software Publishing" -Name State -Value 146432
		Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name CertificateRevocation -Value 1
		"IntOps setting " + (get-date) | Out-File -Encoding Ascii -append $log
		$CDBP = "s3://$artbkt/CDBSExtract_$lhd.ps1"
		$CDBL = "C:\ProgramData\Spark Dental Technology\Scripts\CDBSExtract.ps1"
		aws s3 cp $CDBP $CDBL
		"CDBSEx " + (get-date) | Out-File -Encoding Ascii -append $log
		"Check IIS " + (get-date) | Out-File -Encoding Ascii -append $log
		$fqdn= [System.Net.Dns]::GetHostByName($env:computerName).hostname
		$domain= "https://$fqdn/Titanium"
		$return = $null
		do {
			Try{
				$return = Invoke-WebRequest -URI $domain"/license.svc/ajaxEndpoint/ImportLicenseFile" -DisableKeepAlive -UseBasicParsing -Method Post 
			}
			Catch{
				"#Fail: " + (get-date) + "  Reason: " + "$_" | Out-File -Encoding Ascii -append $log
				Start-Sleep -Seconds 10
				$return = $null
			}
		} while ($return -eq $null)
		"IIS up,apply Ti lic " + (get-date) | Out-File -Encoding Ascii -append $log
		$licP= "s3://$artbkt/$lhd/NSW-eHealth-$lhd-Prod-60-CDBS.lic"
		aws s3 cp $licP c:\temp\app1\NSW-AWS-Staging.lic
		"Web Lic " + (get-date) | Out-File -Encoding Ascii -append $log
		$uploadPath = "c:\temp\app1\NSW-AWS-Staging.lic"
		$uploadFile = Split-Path $uploadPath -leaf
		$fileBytes = [System.IO.File]::ReadAllBytes($uploadPath);
		$fileEnc = [System.Text.Encoding]::GetEncoding('ISO-8859-1').GetString($fileBytes);
		$boundary = [System.Guid]::NewGuid().ToString(); 
		$LF = "`r`n";
		$bodyLines = ( 
			"--$boundary", 
			"Content-Disposition: form-data; name=`"file`"; filename=`"$uploadFile`"",
			"Content-Type: application/octet-stream$LF",
			$fileEnc,
			"--$boundary--$LF"
		) -join $LF 
		Invoke-WebRequest -uri $domain"/api/Account/Login" -ContentType "application/json" -Headers @{'x-requested-with' = 'XMLHttpRequest';} -SessionVariable SetCookie -Method Post -body "{userName:'$tiAdmin', password: '$tiPwd', setCookie: true, clinic: 'Walgett'}"
		Invoke-RestMethod -Uri $domain"/license.svc/ajaxEndpoint/ImportLicenseFile" -ContentType "multipart/form-data; boundary=`"$boundary`"" -WebSession $SetCookie -Method Post -Body $bodyLines
		aws ec2 create-tags --resources $instance_id --tags Key=licensed,Value=true
		"WebLic done " + (get-date) | Out-File -Encoding Ascii -append $log
	}
} else {
	
}
</powershell>
<persist>true</persist>