Param(
    [Parameter(Mandatory=$true)][string]$configDir,
    [Parameter(Mandatory=$true)][string]$templatePath,
    [Parameter(Mandatory=$true)][string]$serverIP,
    [Parameter(Mandatory=$true)][string]$rabbitUser,
    [Parameter(Mandatory=$true)][string]$logDir,
    [Parameter(Mandatory=$true)][string]$lockPath
)

$scriptLocation = [System.IO.Path]::GetDirectoryName($myInvocation.MyCommand.Definition)
. "$scriptLocation\utils.ps1"


$serverIP =  (Get-NetIPAddress -AddressFamily IPv4 -PrefixOrigin Dhcp).IPAddress
$volumeDriver = 'cinder.volume.drivers.windows.smbfs.WindowsSmbfsDriver'
$smbSharesConfigPath = "$configDir\smbfs_shares_config.txt"
$configFile = "$configDir\cinder.conf"


$sharePath = "//$serverIP/SMBShare"
sc $smbSharesConfigPath $sharePath

$template = gc $templatePath
$config = expand_template $template
Write-Host "Config file:"
Write-Host $config
sc $configFile $config

# FIX FOR qmeu-img - fetch locally compiled one
Invoke-WebRequest -Uri http://10.0.110.1/qemu-img-cbsl-build.zip -OutFile c:\qemu-img\qemu-img-cbsl-build.zip
if (! (Test-Path -Path c:\qemu2))
{
	mkdir c:\qemu2
}
#else
#{
#	Remove-Item -Force -Recurse c:\qemu2
#}
unzip c:\qemu-img\qemu-img-cbsl-build.zip c:\qemu2
Move-Item -Path C:\qemu2\* -Destination C:\qemu-img\ -Force

# Ensure Windows Share is available
if (! (Test-Path -Path C:\SMBShare))
{
    mkdir c:\SMBShare
}

if (!(Get-SMBShare -Name SMBShare))
{
    $hostname=hostname
    New-SMBShare -Name SMBShare -Path C:\SMBShare -FullAccess "$hostname\Administrator"
}
Grant-SmbShareAccess -Name SMBShare -AccountName Administrator -AccessRight Full -Force
