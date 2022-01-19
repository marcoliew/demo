# Determine Windows OS to use relevant Sysprep files
if([System.Environment]::OSVersion.Version.Major -eq 6){
 cd "C:\Program Files\Amazon\Ec2ConfigService"
 .\ec2config.exe -sysprep
 }
 else {
 cd "C:\ProgramData\Amazon\EC2-Windows\Launch\Scripts"
 .\InitializeInstance.ps1 -Schedule
 .\SysprepInstance.ps1
 }
#=======
echo "Running InitializeInstance"
& Powershell.exe C:/ProgramData/Amazon/EC2-Windows/Launch/Scripts/InitializeInstance.ps1 -Schedule
if ($LASTEXITCODE -ne 0) {
 throw("Failed to run InitializeInstance")
}
 
echo "Running Sysprep Instance"
& Powershell.exe C:/ProgramData/Amazon/EC2-Windows/Launch/Scripts/SysprepInstance.ps1 -NoShutdown
if ($LASTEXITCODE -ne 0) {
 throw("Failed to run Sysprep")
}
Start-Sleep -Seconds 60
Stop-Computer
