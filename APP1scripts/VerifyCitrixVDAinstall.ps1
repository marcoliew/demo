$source='Citrix*Virtual*Delivery*Agent*'
Write-host "Verifying the Citrix VDA installation"
Do
{
$installed = (Get-ItemProperty HKLM:\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\* |Where-Object {$_.Displayname -like $source }| Select-Object -ExpandProperty "DisplayName")
if ($installed -ne ""){
Write-host "Citrix is successfully installed"
Write-host "Image is ready for build"
break
}
start-sleep -Seconds 60
} While (-Not $installed)