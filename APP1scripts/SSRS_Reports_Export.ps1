$sourceRsUri = "http://virtAPP1-mdb002/ReportServer/ReportService2019.asmx?wsdl"
#Declare Proxy so we dont need to connect with every command
$proxy = New-RsWebServiceProxy -ReportServerUri $sourceRsUri
#Output ALL Catalog items to file system
Out-RsFolderContent -Proxy $proxy -RsFolder / -Destination 'C:\SSRS_Out' -Recurse