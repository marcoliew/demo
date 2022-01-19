#Load required assemblies
[reflection.assembly]::LoadWithPartialName("Microsoft.SqlServer.Smo")
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoExtended") | Out-Null
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.ConnectionInfo") | Out-Null
[Reflection.Assembly]::LoadWithPartialName("Microsoft.SqlServer.SmoEnum") | Out-Null

$lhd="branch2"
$SGpath="\\10.104.82.86\dependencies-prod-app1-sqlnativebackup"
$dest= "K:\$lhd\"
$server = New-Object ("Microsoft.SqlServer.Management.Smo.Server") $dbInstance
$src="D:\DB_Dump\$lhd\"
New-PSDrive –Name “K” –PSProvider FileSystem –Root “$SGpath”

mkdir "D:\DB_Dump\$lhd"
mkdir "K:\$lhd"


Write-Host "Starting DB backup"
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

#Allow time for backup
$server.ConnectionContext.StatementTimeout = 0

#Backup Database
$MachineName = (Get-WmiObject -Class Win32_ComputerSystem -Property Name).Name
$myarr=@($RelocateData,$RelocateLog)
$backupfile1 = "$src\branch2_Titanium1.bak"
$backupfile2 = "$src\branch2_Titanium2.bak" 
$backupfile3 = "$src\branch2_Titanium3.bak"
$backupfile4 = "$src\branch2_Titanium4.bak"
$dbname = 'branch2_Titanium'
Backup-SqlDatabase -ServerInstance $MachineName -Database $dbname -BackupFile $backupfile1,$backupfile2,$backupfile3,$backupfile4 -CompressionOption On

[int]$elapsedMinutes = $stopwatch.Elapsed.Minutes

Write-Host "Backup Completed in $elapsedMinutes Minutes"

$stopwatch.Stop()

Push-Location -Path $PSScriptRoot

Write-Host "Uploading to S3"

Function Copy-WithProgress
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0)]
        $Source,
        [Parameter(Mandatory=$true,
            ValueFromPipelineByPropertyName=$true,
            Position=0)]
        $Destination
    )

    $Source=$Source.tolower()
    $Filelist=Get-Childitem "$Source" –Recurse
    $Total=$Filelist.count
    $Position=0

    foreach ($File in $Filelist)
    {
        $Filename=$File.Fullname.tolower().replace($Source,'')
        $DestinationFile=($Destination+$Filename)
        Write-Progress -Activity "Copying data from '$source' to '$Destination'" -Status "Copying File $Filename" -PercentComplete (($Position/$total)*100)
        Copy-Item $File.FullName -Destination $DestinationFile
        $Position++
    }
}

$stopwatch.Start()

Copy-WithProgress -Source $src -Destination $dest

Write-Host "S3 Upload Completed in $elapsedMinutes Minutes"

$stopwatch.Stop()

